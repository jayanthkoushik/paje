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

    // update source for images with dark/light versions
    $('img[data-darksrc][data-darksrc!=""]').attr(
        'src',
        function(){
            if (!($(this).is('[data-lightsrc]'))) {
                $(this).attr('data-lightsrc', $(this).attr('src'));
            }
            return $(this).attr(theme === 'dark' ? 'data-darksrc' : 'data-lightsrc');
        }
    );
}

function replaceTag(target, repl) {
    $(target).replaceWith(function() {
        var replElem = $("<" + repl + ">");
        replElem.html($(this).html());
        var thisAttrs = $(this).prop("attributes");
        $.each(thisAttrs, function() {
            replElem.attr(this.name, this.value);
        });
        return replElem;
    });
}

window.addEventListener('DOMContentLoaded', () => {
    setTheme(getPreferedTheme());
    $('table').addClass('table mx-auto w-auto');
    $('tbody').addClass('table-group-divider');
    replaceTag("h5", "h6");
    replaceTag("h4", "h5");
    replaceTag("h3", "h4");
    replaceTag("h2", "h3");
    replaceTag("h1:not('#title')", "h2");
    replaceTag("section#footnotes", "div");

    $(".subfigures").each(function() {
        var figs = $(this).children("figure");
        figs.addClass("subfigure");
        var cap = $(this).children("figcaption");
        var figsDiv = $("<div>");
        figsDiv.addClass("d-flex justify-content-evenly");
        figsDiv.html(figs);
        $(this).html(figsDiv);
        $(this).append(cap);
    });
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
