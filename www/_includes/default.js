function getPreferredTheme() {
    const storedTheme = localStorage.getItem('theme');
    if (storedTheme === 'dark' || storedTheme === 'light') {
        return storedTheme;
    }
    return 'auto';
}

function setTheme(theme) {
    var coreTheme;
    if (theme === 'dark' || theme === 'light') {
        coreTheme = theme;
    } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        coreTheme = 'dark';
    } else {
        coreTheme = 'light';
    }

    // Set global theme.
    document.documentElement.setAttribute('data-bs-theme', coreTheme);

    // Update themed images.
    const themeSrc = coreTheme === 'dark' ? 'data-darksrc' : 'data-lightsrc';
    document.querySelectorAll('img[data-darksrc]').forEach((img) => {
        const newSrc = img.getAttribute(themeSrc);
        if (img.getAttribute('src') !== newSrc) {
            img.setAttribute('src', newSrc);
        }
    });

    // Update theme selector.
    document.querySelectorAll('.theme-button').forEach((themeBtn) => {
        if (themeBtn.getAttribute('data-bs-theme-value') === theme) {
            themeBtn.classList.add('active');
            const themeSvg = themeBtn.querySelector('svg').cloneNode(true);
            document.getElementById('active-theme-button').replaceChildren(themeSvg);
        } else {
            themeBtn.classList.remove('active');
        }
    });
}

document.querySelectorAll('.theme-button').forEach((themeBtn) => {
    themeBtn.addEventListener('click', function () {
        const theme = this.getAttribute('data-bs-theme-value');
        if (theme === 'dark' || theme === 'light') {
            localStorage.setItem('theme', theme);
        } else {
            localStorage.removeItem('theme');
        }
        setTheme(theme);
    });
});

window.addEventListener('DOMContentLoaded', () => {
    setTheme(getPreferredTheme());

    const domParser = new DOMParser();
    const coreTheme = document.documentElement.getAttribute('data-bs-theme');
    const themeSrc = coreTheme === 'dark' ? 'data-darksrc' : 'data-lightsrc';
    document.querySelectorAll('.img-noscript').forEach((noscript) => {
        const img = domParser.parseFromString(
            noscript.innerHTML, 'text/html'
        ).getElementsByTagName('img')[0];
        img.setAttribute('src', img.getAttribute(themeSrc));
        noscript.replaceWith(img);
    });

    document.querySelectorAll('.author a').forEach((authorLink) => {
        authorLink.setAttribute('tabindex', '0');
        authorLink.setAttribute('role', 'button');
        authorLink.setAttribute('class', 'author-link');
    });

    const tooltips = [...document.querySelectorAll('[data-bs-toggle="tooltip"]')].map(
        tooltipTrigger => new bootstrap.Tooltip(tooltipTrigger)
    );
    const popovers = [...document.querySelectorAll('[data-bs-toggle="popover"]')].map(
        popoverTrigger => new bootstrap.Popover(popoverTrigger)
    );

    document.querySelectorAll('.citation a, a.footnote-ref').forEach((citLink) => {
        citLink.removeAttribute('href');
    });
    document.querySelectorAll('#footnotes, .inst-nojs').forEach((nojsElem) => {
        nojsElem.remove(); }
    );
});

window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (getPreferredTheme() === 'auto') {
        setTheme('auto');
    }
});
