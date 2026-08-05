import json
import boto3
import pytest
from moto import mock_aws

TABLE_NAME = 'cloud-resume-visitors'

@pytest.fixture
def dynamodb_table():
    with mock_aws():
        client = boto3.client('dynamodb', region_name='us-east-1')
        client.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        table = boto3.resource('dynamodb', region_name='us-east-1').Table(TABLE_NAME)
        table.put_item(Item={'id': 'visitor_count', 'count': 5})
        yield table


@pytest.fixture
def empty_dynamodb_table():
    with mock_aws():
        client = boto3.client('dynamodb', region_name='us-east-1')
        client.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'id', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        table = boto3.resource('dynamodb', region_name='us-east-1').Table(TABLE_NAME)
        yield table


@pytest.fixture
def missing_dynamodb_table():
    with mock_aws():
        # Table is never created, so calls against it fail with
        # ResourceNotFoundException - simulates the database being down/missing.
        table = boto3.resource('dynamodb', region_name='us-east-1').Table(TABLE_NAME)
        yield table


def test_post_increments_count(dynamodb_table, monkeypatch):
    import lambda_function
    monkeypatch.setattr(lambda_function, 'table', dynamodb_table)

    response = lambda_function.lambda_handler({'httpMethod': 'POST'}, None)
    body = json.loads(response['body'])

    assert response['statusCode'] == 200
    assert body['count'] == 6


def test_get_does_not_increment(dynamodb_table, monkeypatch):
    import lambda_function
    monkeypatch.setattr(lambda_function, 'table', dynamodb_table)

    response = lambda_function.lambda_handler({'httpMethod': 'GET'}, None)
    body = json.loads(response['body'])

    assert body['count'] == 5


def test_cors_header_present(dynamodb_table, monkeypatch):
    import lambda_function
    monkeypatch.setattr(lambda_function, 'table', dynamodb_table)

    response = lambda_function.lambda_handler({'httpMethod': 'GET'}, None)
    assert response['headers']['Access-Control-Allow-Origin'] == 'https://randy-sykes.me'


def test_get_missing_item_returns_zero(empty_dynamodb_table, monkeypatch):
    import lambda_function
    monkeypatch.setattr(lambda_function, 'table', empty_dynamodb_table)

    response = lambda_function.lambda_handler({'httpMethod': 'GET'}, None)
    body = json.loads(response['body'])

    assert response['statusCode'] == 200
    assert body['count'] == 0


def test_get_database_unavailable_returns_500(missing_dynamodb_table, monkeypatch):
    import lambda_function
    monkeypatch.setattr(lambda_function, 'table', missing_dynamodb_table)

    response = lambda_function.lambda_handler({'httpMethod': 'GET'}, None)
    body = json.loads(response['body'])

    assert response['statusCode'] == 500
    assert 'error' in body
    assert response['headers']['Access-Control-Allow-Origin'] == 'https://randy-sykes.me'


def test_post_database_unavailable_returns_500(missing_dynamodb_table, monkeypatch):
    import lambda_function
    monkeypatch.setattr(lambda_function, 'table', missing_dynamodb_table)

    response = lambda_function.lambda_handler({'httpMethod': 'POST'}, None)
    body = json.loads(response['body'])

    assert response['statusCode'] == 500
    assert 'error' in body
    assert response['headers']['Access-Control-Allow-Origin'] == 'https://randy-sykes.me'

