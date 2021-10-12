$('#theme-switch').on('click', function () {
    var newTheme = $('body').hasClass('dark-theme') ? 'light' : 'dark';
    setTheme(newTheme);
});

$(document).ready(function () {
    var wantDark = getURLParameter('dark');
    var wantLight = getURLParameter('light');

    if (wantDark === true) {
        setTheme('dark');
    } else if (wantLight === true) {
        setTheme('light');
    } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        // don't modify urls or history when following media query preference
        setTheme('dark', modLinks=false);
    } else {
        setTheme('light', modLinks=false);
    }

    $('table').wrap('<div class="table-responsive"></div>');

    $('.math.display').wrap('<span class="math-display-wrap"></span>');

    $('#appendix #refs').remove();
    $('#appendix .footnotes').remove();

    $('#appendix .header-section-number').each(function(index) {
        var q = Math.floor(index / 26) + 1;
        var r = index % 26;
        var secChr = String.fromCharCode(65 + r);
        $(this).text(secChr.repeat(q));
    });

    $('#appendix figcaption').each(function(index) {
        var cap = $(this).text().replace(/^Figure /, 'Figure S');
        $(this).text(cap);
        $(this).siblings('img').prop('alt', cap);
    });
    $('#appendix table caption').each(function(index) {
        var cap = $(this).text();
        $(this).text(cap.replace(/^Table /, 'Table S'));
    });
});

function setTheme(theme, modLinks=true) {
    if (theme === 'dark') {
        $('body').addClass('dark-theme');
    } else {
        $('body').removeClass('dark-theme');
    }

    var otherTheme = theme === 'dark' ? 'light' : 'dark';
    // svg sources from https://github.com/tabler/tabler-icons
    if (otherTheme === 'dark') {
        // moon icon
        $('#theme-switch').html('<svg style="fill: currentColor"><path d="M16.2 4a9.03 9.03 0 1 0 3.9 12a6.5 6.5 0 1 1 -3.9 -12" /></svg>');
    } else {
        // sun icon
        $('#theme-switch').html('<svg style="fill: none"><circle cx="12" cy="12" r="4" /><path d="M3 12h1M12 3v1M20 12h1M12 20v1M5.6 5.6l.7 .7M18.4 5.6l-.7 .7M17.7 17.7l.7 .7M6.3 17.7l-.7 .7" /></svg>');
    }

    if (modLinks === true) {
        $('.local-link').each(function() {
            var href = $(this)[0].href.split('?', 1)[0];
            $(this)[0].href = href + '?' + theme;
        });

        history.replaceState({theme: true}, document.title, '?' + theme);
    }
}

function getURLParameter(param) {
    var params = window.location.search.substring(1).split('&');
    for (var i = 0; i < params.length; i++) {
        var param_val_i = params[i].split('=');
        if (param_val_i[0] === param) {
            if (param_val_i[1] === undefined) {
                return true;
            } else {
                return decodeURIComponent(param_val_i[1]);
            }
        }
    }
};
