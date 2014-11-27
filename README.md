<!--
Markdown live preview: http://tmpvar.com/markdown.html
-->

# Concepts

    Init  Plugin1  Plugin2  ...  PluginN  Postinstall  Finish
      |------|--------|-------------|----------|----------|


Ubiquity collects answers of questions from plugins, and then starts to install
system based on these configuration values in Debconf.

Send filtered Debconf commands to selected frontend to communicate with Debconf.

## Ubiquity Greeter and OEM Mode

Greeter gives user two choices: install system directly, or try the system first.

OEM mode (TBD)

## Ubiquity Plugins

[Ubiquity Plugins](https://wiki.ubuntu.com/Ubiquity/Plugins) is used to:

 1. Collect user's configurations
 1. Execute specific actions

Execution order of Ubiquity plugins:

 1. language
 1. prepare
  1. check available drive space and Internet connection, download updates, etc.
 1. wireless
 1. partman
 1. timezone
 1. console-setup
 1. usersetup
 1. network
 1. tasks
 1. webcam

### oem-config

 1. language
 1. timezone
 1. console-setup
 1. usersetup

### Try Ubuntu without Installing

 1. language
 1. wireless
 1. prepare
 1. partman
 1. timezone
 1. keyboard
 1. usersetup
 1. <post-install>
 1. <reboot>

## Cooperate with Debian Installer

TBD

## Q&A

Q1: How does a plugin communicate (get/set) with Debconf?

--------------------------------------------------------------------------------
# Debinan pakcages created by Ubiquity

<table>
<tr>
  <td>oem-config</td>
  <td>Perform end-user configuration after initial OEM installation</td>
</tr>
<tr>
  <td>oem-config-check</td>
  <td>enter OEM mode if requested</td>
</tr>
<tr>
  <td>oem-config-{debconf,gtk,kde}</td>
  <td>debconf/GTK+/KDE frontend for end-user post-OEM-install configuration</td>
</tr>
<tr>
  <td>oem-config-remaster</td>
  <td>Remaster a CD with additional oem-config functionality</td>
</tr>
<tr>
  <td>oem-config-udeb</td>
  <td>Prepare for OEM configuration</td>
</tr>
<tr>
  <td>ubiquity</td>
  <td>Ubuntu live CD installer</td>
</tr>
<tr>
  <td>ubiquity-frontend-{debconf,gtk,kde}</td>
  <td>debconf/GTK+/KDE frontend for Ubiquity live installer</td>
</tr>
<tr>
  <td>ubiquity-ubuntu-artwork</td>
  <td>Ubuntu artwork for Ubiquity live installer</td>
</tr>
</table>

**oem-config.install**

 * bin/oem-config-firstboot usr/sbin
 * bin/oem-config-prepare usr/sbin
 * bin/oem-config-remove usr/sbin
 * bin/oem-config-wrapper usr/sbin
 * scripts/ubi-reload-keyboard /usr/lib/oem-config/post-install

**oem-config-check.install**

 * debian-installer-startup.d lib
 * main-menu.d lib

**oem-config-gtk.install**

 * Replace part of oem-config.
 * desktop/oem-config-prepare-gtk.desktop usr/share/ubiquity/desktop
 * bin/oem-config-remove-gtk usr/sbin

**oem-config-remaster.install**

 * bin/oem-config-remaster usr/sbin

**oem-config-udeb.install**

 * finish-install.d usr/lib

--------------------------------------------------------------------------------
# Debugging

* [Hacking on Ubiquity, the setup](http://agateau.com/2013/04/30/hacking-on-ubiquity-the-setup/)
* [Debugging Ubiquity](https://wiki.ubuntu.com/DebuggingUbiquity)
* [Ubiquity (kubuntu wiki)](https://wiki.kubuntu.org/Ubiquity)
* [Custimize Live Initrd](https://wiki.ubuntu.com/CustomizeLiveInitrd)

kernel commandline parameter

* phase 1: automatic-ubiquity
* phase 2: automatic-ubiquity
* phase 3:
 * # ubiquity-dm <vt> <display> <username> <program> [<arguments>]
 * ubiquity-dm vt7 :0 oem /usr/sbin/oem-config-wrapper --only --debug

## Utilities Usage

* For host
 * debug-init: Initialize host debugging environment and provide mount/umount/ssh commands to access target remotely.
* For target
 * debug-ubiquity.sh: Launch Ubiquity with proper debugging parameters.

## Workflow

    # launch ubiquity
    host $ ./debug-init ssh
    targ $ ./debug-ubiquity.sh start &
    targ $ DISPLAY=:0 gnome-terminal &

    # modify ubiquity
    host $ vim mnt/<target file>

## Log Files

/var/log/installer/dm
/var/log/installer/syslog
/var/log/installer/debug
/var/log/oem-config.log

## Other Tips

* Print debugging messages directly via syslog.syslog().
* Use watch command to monitor syslog.
 * $ watch -n 1 tail -n 30 /var/log/syslog

--------------------------------------------------------------------------------
# Source Code Structure

## Code Flow

    # GRUB parameters
    #   * only-ubiquity
    #     - ubiquity=1
    #   * debug-ubiquity
    #     - ubiquity=1
    #     - debug="-d"
    #   * automatic-ubiquity
    #     - ubiquity=1
    #     - automatic="--automatic"
    #   * maybe-ubiquity
    #     - ubiquity=1
    #     - choose="--greeter"
    #   * ldtp-ubiquity
    #     - ubiquity=1
    #     - ldtp="--ldtp"
    #   * noninteractive
    #     - ubiquity=1
    #     - noninteractive=1
    #   * ubiquity/frontend=*
    #     - frontend="${x#*=}"
    #
    # Note:
    #   1. In official Ubuntu image, `only-ubiquity' is used if installation-related option is chose.
    #   2. In Somerville image, kernel parameter `automatic-ubiquity' is used in phase1 and phase2.
    debian/ubiquity.ubiquity.upstart
    `-- ubiquity-dm
        `-- ubiquity (/usr/bin/ubiquity, it is called ubiquity-wrapper in source tree)
            `-- ubiquity (the real installer which is at /usr/lib/ubiquity/bin/ubiquity)
                |-- # Set locale to UTF-8
                |-- # Parse CLI args
                |-- # Set environment variables
                |-- # Set proper authority
                `-- install()
                    `-- wizard.run()
                        |-- # [Disablers Phase]
                        |-- disable_{volume_manager, screensaver, powermgr}()
                        |
                        |-- # [Install Phase]
                        |   # Execute plugin pages.
                        |   #   * GUI with/without dbfilter.
                        |   #     * If with dbfilter, it's Page or Install.
                        |-- on_next_clicked()
                        |   |-- dbfilter.ok_handler()
                        |   |   `-- debconffilter_done()
                        |   |       `-- find_next_step()
                        |   |           `-- # Check finished_step and execute
                        |   |               # dbfilter.start(), ex:
                        |   |               #  * normal plugins
                        |   |               #  * ubi-partman
                        |   |               #  * ubiquity.component.partman_commit
                        |   |               #  * ubiquity.component.install
                        |   |               #  * ubiquity.component.plugininstall
                        |   `-- find_next_step()  # if dbfilter is None
                        |       `-- # The same as above
                        |
                        |-- # [Postinstall Phase]
                        |   # 1. postinstall starts after all the questions are
                        |   #    answered and slideshow appears.
                        |   # 2. plugininstall.py executes the install actions of plugins.
                        |   #   * prepare() returns /usr/share/ubiquity/plugininstall.py
                        |   #     - Execute configure_{python, network, locale, apt}()
                        |   #     - Execute configure_plugins()
                        |   #       + Execute Install of plugins
                        |   #     - Execute run_target_config_hooks()
                        |   #     - Execute install_language_packs()
                        |   #     - Execute remove_unusuable_kernels()
                        |   #     - Execute configure_hardware()
                        |   #     - Execute install_oem_extras() or install_extras()
                        |   #     - Execute configure_bootloader()
                        |   #     - Execute remove_oem_extras() or remove_extras()
                        |   #     - Execute install_restricted_extras()
                        |   #     - ...
                        |-- start_slideshow()
                        |
                        `-- # [Success Commands]
                            # 1. Get ubiquity/install/success_command and execute the result.

    oem-config.oem-config.upstart
    `-- oem-config-firstboot
        |-- oem-config/early_command
        `-- oem-config-wrapper
            |-- oem-config  # symbolic link of /usr/lib/ubiquity/bin/ubiquity
            |   |           # which is the real installer.  /usr/bin/ubiquity
            |   |           # also launch the installer.
            |   `-- run_oem_hooks() (if oem_config is True)
            |       `-- # Run hook scripts in /usr/lib/oem-config/post-install
            |-- oem-config/late_command
            `-- oem-config-remove-gtk  # Remove ubiquity-related packages

## Components Relationship
                             I                                   I              +plugin------------------------+
             UntrustedBase -----> plugin.PluginUI ------------------------------> PageBase ---> Page<frontend> |
                             |                                                  |                              |
                             v                                                  |                              |
    DebconfFilter ---> FilteredCommand                                          |                              |
                             |                                                  |                              |
                             | I                   I                            |                              |
                             |---> plugin.Plugin -------------------------------> Page                         |
                             |                     |                            |                              |
                             |                     `--> plugin.InstallPlugin ---> Install                      |
                             |                                                  |                              |
                             | I                                                +------------------------------+
                             |---> components.install.Install
                             |
                             | I
                             `---> components.plugininstall.Install (dbfilter)
                                                    |
                                                    |
                                +frontend-----------v----+
                                | Controller ---> Wizard |
                                +-------------------|----+
                                                    |
                                                    v
                                                 Ubiquity

    +--------------------------------+
    |    I                           |
    | A ---> B: A is inheritted by B |
    |                                |
    | A ---> B: A is used by B       |
    +--------------------------------+

## Component Descriptions

* Wizard: The core component of Ubiquity
 * Every frontend provides its Wizard.
 * init(): sets up plugins.
 * run(): the main part.
  * Get user inputs via pages.
  * Postinstall with slideshow.
  * Quit/reboot/shutdown.
 * find_next_step():
 * debconffilter_done():

* Controller: Define the control in a plugin.
 * Every frontend provides its Controller.
 * Provide the common GUI framework for plugins?

* FilteredCommand:
 * Prepare executable command, questions, and environment variables to DebconfFilter for communicating with Debconf.
 * Inherited by plugins.
 * ok_handler(): when ok or forward is selected.
  * Triggered by GUI ok/forward button handler (on_next_clicked()). 
  * Execute frontend.debconffilter_done(). (entry point of postinstall?)
 * prepare()
  * Return (executable-command, questions, environ)

* DebconfFilter: Filte a debconf command from another process and execute it
 * Get a command from another process, check it with the valid_command, execute the valid command
 * Input:
  * db: DebconfCommunicator object
  * widgets: Refer to Glossary.

* UntrustedBase: Base template class for accessing Debconf?

* DebconfCommunicator: Wrapper of debconf-communicate used by frontends.

## Misc
execute plugins
postinstall (triggerred by the last "on_next_clicked")

    plugin
      from ubiquity.filteredcommand import FilteredCommand, UntrustedBase
      
      class PluginUI(UntrustedBase):
          def __init__(self, *args, **kwargs):
      
      class Plugin(FilteredCommand):
          def prepare(self, unfiltered=False):
              # None causes dbfilter to just spin a main loop and wait for OK/Cancel
              return None
      
      class InstallPlugin(Plugin):
          def install(self, *args, **kwargs):
              return self.run_command(auto_process=True)
    
    
    debconffilter
    
    [Frontend]
    class Component
        self.controller  # instance of Controller

    class Controller
        self._wizard = wizard  # instance of Wizard

       # Define frontend's page actions.  <plugin>.controller
    
    class BaseFrontend


    class Wizard(BaseFrontend)
      # Primary structure of GUI.  Collecte system configs from user
    
      self.modules  # list containing ordered plugins
      self.pages    # list containing configured modules in the module list (self.modules)
    
      def run()
    
      def find_next_step():
        # end of collecting system configs
        if finished_step == last_page:
          dbfilter = plugininstall.Install(self)
          dbfilter.start(auto_process=True)
    
    ## Execute plugininstall
    # ubiquity/components/plugininstall.py
    class Install(FilteredCommand):
      # does not overwrite start()
    
      def prepare():
        return (['/usr/share/ubiquity/plugininstall.py'], questions)
    
      def run():
        return FilteredCommand.run(self, priority, question)
    
    # ubiquity/filtercommand.py
    class FilteredCommand(UntrustedBase):
      def run():
    
      def start():
        prep = self.prepare()
    
        self.command = ['log-output', '-t', PACKAGE, '--pass-stdout']
        if isinstance(prep[0], types.StringTypes):
          self.command.append(prep[0])
        else:
          self.command.extend(prep[0])
    
        self.dbfilter = DebconfFilter(self.db, widgets)
    
        if auto_process:
          self.dbfilter.start(self.command, blocking=False, extra_env=env)
        else:
          self.dbfilter.start(self.command, blocking=True, extra_env=env)
    
    # ubiquity/debconffilter
    class DebconfFilter:
      def start():

## Environment Variables

* UBIQUITY_A11Y_PROFILE
* UBIQUITY_AUTOMATIC
* UBIQUITY_AUTOPILOT
* UBIQUITY_BTERM
* UBIQUITY_CTTY
* UBIQUITY_DEBUG
 * If UBIQUITY_DEBUG is enabled
  * UBIQUITY_DEBUG_CORE = '1'
  * DEBCONF_DEBUG = 'developer'
* UBIQUITY_DEBUG_CORE
 * Enable debugging message for debconffilter and filteredcommand.
* UBIQUITY_DEBUG_PDB
* UBIQUITY_FRONTEND
* UBIQUITY_GLADE
* UBIQUITY_GREETER
* UBIQUITY_LDTP
* UBIQUITY_NO_BOOTLOADER
* UBIQUITY_NO_GTK
* UBIQUITY_NO_KDE
* UBIQUITY_NO_TESTS
* UBIQUITY_OEM_USER_CONFIG
 * Set to '1' if oem-config is executed rather than ubiquity.
 * Debugging messages are logged in /var/log/oem-config.log
* UBIQUITY_ONLY
* UBIQUITY_PATH
* UBIQUITY_PID
* UBIQUITY_PKGS
* UBIQUITY_PLUGIN_PATH
* UBIQUITY_TEST_INSTALLED
* UBIQUITY_TEST_SHOW_ALL_PAGES
* UBIQUITY_TEST_SLIDESHOW
* UBIQUITY_TYPE_MOCK_RESOLVER
* UBIQUITY_WIRELESS
* UBIQUITY_WRAPPER_DEBUG

--------------------------------------------------------------------------------
# Ubiquity Plugins, More Information

Page<frontend> and Page
 * PageGtk will be executed to setup the GUI.
 * Page.run will be executed to enter main loop.
  * self.ui equals to the PageGtk instance?
  * Page is not necessary for a GUI-only plugin.  For example, dell-eula does not have Page and can work.

Install
 * Plugin actions executed in the postinstall phase.

Plugin Structure

    from ubiquity import plugin
    |-- plugin.PluginUI
    |     |-- PageBase
    |     |     PageGtk
    |     |     PageKde
    |     |     PageNoninteractive
    |     |       __init__
    |     |       set_language
    |     |       get_language
    |     `--   PageDebconf
    |             __init__
    |   
    |-- plugin.Plugin
    |     Page
    |       prepare
    |       run
    |       cancel_handler
    |       ok_handler
    |       cleanup
    |   
    `-- plugin.InstallPlugin
          Install
            prepare (optional)
            install

--------------------------------------------------------------------------------
# Bootloader-Related Information

## GRUB Options

    setparams 'Try Ubuntu without installing'
        set gfxpayload=keep
        linux /casper/vmlinuz.efi file=/cdrom/preseed/ubuntu.seed boot=casper quiet splash --
        initrd /casper/initrd.lz
        # Enter system, the "Install Ubuntu 14.10" button on desktop
        #   * it is ubiquity.desktop which executes "sh -c 'ubiquity gtk_ui'"
    
    setparams 'Install Ubuntu'
        set gfxpayload=keep
        linux /casper/vmlinuz.efi file=/cdrom/preseed/ubuntu.seed boot=casper only-ubiquity quiet splash --
        initrd /casper/initrd.lz
    
    setparams 'OEM install (for manufacturers)'
        set gfxpayload=keep
        linux /casper/vmlinuz.efi file=/cdrom/preseed/ubuntu.seed boot=casper only-ubiquity quiet splash oem-config/enable=true --
        initrd /casper/initrd.lz
    
    setparams 'Check disc for defects'
        set gfxpayload=keep
        # initrd.lz/scripts/casper-bottom/01integrity_check
        # `-- casper-md5check
        linux /casper/vmlinuz.efi file=/cdrom/preseed/ubuntu.seed boot=casper integrity-check quiet splash --
        initrd /casper/initrd.lz

--------------------------------------------------------------------------------
# Glossary

oem-config

question patterns
  Used to find widgets whose patterns map the given question(s) via re.search.

  * localechooser/languagelist
  * ^time/zone$, ^tzsetup/detected$, CAPB, PROGRESS
  * ^keyboard-configuration/layout, ^keyboard-configuration/variant, ^keyboard-configuration/model, ^keyboard-configuration/altgr$, ^keyboard-configuration/unsupported_
  * ^passwd/user-fullname$, ^passwd/username$, ^passwd/user-password$, ^passwd/user-password-again$, ERROR
  * ^.*/apt-install-failed$, ubiquity/install/copying_error/md5, ubiquity/install/new-bootdev, CAPB, ERROR, PROGRESS

widget
widgets
  widgets is a directory whose keys are question patterns, and values indicate to the same widget.

  widget types contain <plugin>.Page and plugininstall.Install object.  Every widget
   ? uses db.<debconf-cmd> to communicate with frontend.
   ? has Debconf commands (widget.<debconf-cmd>).

  For more details, please refer to the comment in debconffilter.py.

--------------------------------------------------------------------------------
# Misc.

All the subsystems are mixed together in the same source tree.  When I trace a
file, it is hard to know where the file is executed in the entire installation
process.
