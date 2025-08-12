i18n = import('i18n')
# define GETTEXT_PACKAGE
add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language:'c')
i18n.gettext(meson.project_name(),
    args: [
        '--directory=' + meson.source_root(),
        '--package-name=' + meson.project_name(),
        '--package-version=2.0',
        '--o=../' + meson.project_name() + '.pot',
        '--keyword=_',
        '--escape',
        '--copyright-holder=Tony George (teejee2008@gmail.com)'        
        ]
)
