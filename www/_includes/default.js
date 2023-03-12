function getPreferedTheme() {
    var storedTheme = localStorage.getItem('theme');
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
    $('html').attr('data-bs-theme', coreTheme);

    // Update themed images.
    $('img[data-darksrc]').attr(
        'src',
        function() {
            return $(this).attr(coreTheme === 'dark' ? 'data-darksrc' : 'data-lightsrc');
        }
    );

    // Update theme selector.
    $('[data-bs-theme-value]').each(function() {
        if ($(this).attr('data-bs-theme-value') === theme) {
            $(this).addClass("active");
            $("#active-theme-button").html($(this).children("svg").clone());
        } else {
            $(this).removeClass("active");
        }
    });
}

$(".theme-button").on("click", function () {
    var theme = $(this).attr('data-bs-theme-value');
    if (theme === 'dark' || theme === 'light') {
        localStorage.setItem('theme', theme);
    } else {
        localStorage.removeItem('theme');
    }
    setTheme(theme);
});

window.addEventListener('DOMContentLoaded', () => {
    setTheme(getPreferedTheme());
    $(".author a").attr({
        tabindex: "0",
        role: "button",
        class: "author-link"
    });
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
    const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
    [...popoverTriggerList].map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));
    $(".citation a, a.footnote-ref").removeAttr("href");
    $("#footnotes").remove();
    $(".inst-nojs").remove();
});


window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (getPreferedTheme() === 'auto') {
        setTheme('auto');
    }
});
