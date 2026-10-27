// Find the button that changes the page theme.
let theme_toggler = document.querySelector('#theme_toggler');

// Switch themes when the button is clicked.
theme_toggler.addEventListener('click', function () {
    // Add or remove the dark theme styles.
    document.body.classList.toggle('dark_mode');

    // Tell screen readers whether dark mode is on.
    theme_toggler.setAttribute(
        'aria-pressed',
        document.body.classList.contains('dark_mode')
    );
});