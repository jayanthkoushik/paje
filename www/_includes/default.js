function getPreferedTheme() {
    var storedTheme = localStorage.getItem('theme');
    if (storedTheme === 'dark' || storedTheme === 'light') {
        return storedTheme;
    } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        return 'dark';
    } else {
        return 'light';
    }
}

function setTheme(theme) {
    $('html').attr('data-bs-theme', theme);

    // svg sources from https://github.com/tabler/tabler-icons
    if (theme === 'light') {
        // moon icon
        $('#theme-switch').html('<svg style="fill: currentColor"><path d="M16.2 4a9.03 9.03 0 1 0 3.9 12a6.5 6.5 0 1 1 -3.9 -12" /></svg>');
    } else {
        // sun icon
        $('#theme-switch').html('<svg style="fill: none"><circle cx="12" cy="12" r="4" /><path d="M3 12h1M12 3v1M20 12h1M12 20v1M5.6 5.6l.7 .7M18.4 5.6l-.7 .7M17.7 17.7l.7 .7M6.3 17.7l-.7 .7" /></svg>');
    }

    $('img[data-darksrc]').attr(
        'src',
        function() {
            return $(this).attr(theme === 'dark' ? 'data-darksrc' : 'data-lightsrc');
        }
    );
}

window.addEventListener('DOMContentLoaded', () => {
    setTheme(getPreferedTheme());
    $(".author a").attr({
        tabindex: "0",
        role: "button",
        class: "author-link"
    })
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
    const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
    [...popoverTriggerList].map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));
    $(".citation a, a.footnote-ref").removeAttr("href");
    $("#footnotes").remove();
    $(".inst-nojs").remove();
});

document.getElementById('theme-switch').addEventListener('click', () => {
    var newTheme = $('html').attr('data-bs-theme') === 'dark' ? 'light' : 'dark';
    setTheme(newTheme);
    localStorage.setItem('theme', newTheme);
});

window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    setTheme(window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
    localStorage.removeItem('theme');
});
