// Typewriter section
const phrases = [
    "Randy Sykes",
    "Infrastructure Engineer",
    "DevOps in progress...",
    "14 years → Cloud native"
];

let pi = 0, ci = 0, deleting = false, pause = 0;

const el = document.getElementById('typewriter');

function type(){
    if ( pause > 0) {
        pause--;
        setTimeout(type, 80);
        return
    }
    const word = phrases[pi];

    if (!deleting) {
        ci++;
        el.textContent = word.slice(0,ci);
        if( ci === word.length ) {
            deleting = true;
            pause = 28
        }
        setTimeout(type, 80);
    } else {
        ci--;
        el.textContent = word.slice(0,ci);
        if ( ci === 0 ) {
            deleting = false;
            pi = (pi+1)%phrases.length;
            pause = 6
        }
        setTimeout(type, 40);
    }
}
type();

// Visitor Counter
const formatCount = n => n.toLocaleString('en-US');
const VISITED_KEY = 'crc_visited';
const method = localStorage.getItem(VISITED_KEY) ? 'GET' : 'POST';

fetch('https://dvdbwu26kg.execute-api.us-east-1.amazonaws.com/resume-visitors/count', { method })
    .then(r => r.json())
    .then(data => {
        localStorage.setItem(VISITED_KEY, 'true');
        document.getElementById('visitorCount').textContent = formatCount(data.count);
        document.getElementById('crcVisitorCount').textContent = formatCount(data.count);
    })
    .catch(() => {}); // so it leaves the — placeholder if it fails

// Handle collapsing/expanding navigation when on small screens
const navToggle = document.getElementById('navToggle');
const navLinks = document.getElementById('navLinks');
navToggle.addEventListener('click', () => {
    const isOpen = navLinks.classList.toggle('open');
    navToggle.classList.toggle('open', isOpen);
    navToggle.setAttribute('aria-expanded', isOpen);
});
navLinks.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        navLinks.classList.remove('open');
        navToggle.classList.remove('open');
        navToggle.setAttribute('aria-expanded', 'false');
    });
});