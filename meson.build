project('conky-manager2', ['c','vala'])

prefix = '/usr'
bindir = prefix + '/bin'
sharedir = prefix + '/share'
launcherdir = sharedir + '/applications'
app_name = 'conky-manager2'

sources = [
        'src/AboutWindow.vala',
        'src/GeneratePreviewWindow.vala',
        'src/Main.vala',
        'src/MainWindow.vala',
        'src/SettingsWindow.vala',
        'src/DonationWindow.vala',
        'src/EditThemeWindow.vala',
        'src/Utility.vala',
        'src/EditWidgetWindow.vala'
]

dependencies = [
    dependency('glib-2.0'),
    dependency('gdk-x11-3.0'),
    dependency('gio-unix-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    dependency('gee-0.8'),
    dependency('json-glib-1.0'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : false)
]

install_data('src/' + app_name + '.desktop', install_dir : launcherdir)
install_data('src/share/pixmaps/' + app_name + '.png', install_dir : sharedir + '/pixmaps')
install_data('src/' + app_name + '.appdata.xml', install_dir : sharedir + '/metainfo')
install_data('man/' + app_name + '.1', install_dir : sharedir + '/man/man1')
install_subdir('src/share/conky-manager2/images', install_dir : sharedir + '/' + app_name)
install_subdir('src/share/conky-manager2/themepacks', install_dir : sharedir + '/' + app_name)

subdir('po')

#vala_lint = find_program('io.elementary.vala-lint', required : false)
#if vala_lint.found()
#    test (
#        'Vala lint',
#        vala_lint,
#        args: ['-d', join_paths(meson.source_root(), 'src')]
#    )
#endif

executable('conky-manager2', sources, install : true, dependencies: dependencies)
