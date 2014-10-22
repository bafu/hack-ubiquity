<!--
Markdown live preview: http://tmpvar.com/markdown.html
-->

# Concepts

    Init  Plugin1  Plugin2  ...  PluginN  Postinstall  Finish
      |------|--------|-------------|----------|----------|


Ubiquity collects answers of questions from plugins, and then starts to install
system based on these configuration values in Debconf.

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
 1. wireless
 1. partman
 1. timezone
 1. console-setup
 1. usersetup
 1. network
 1. tasks
 1. webcam


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

**oem-config-check.install**

 * debian-installer-startup.d lib
 * main-menu.d lib

**oem-config-gtk.install**

 * desktop/oem-config-prepare-gtk.desktop usr/share/ubiquity/desktop
 * bin/oem-config-remove-gtk usr/sbin

**oem-config.install**

 * bin/oem-config-firstboot usr/sbin
 * bin/oem-config-prepare usr/sbin
 * bin/oem-config-remove usr/sbin
 * bin/oem-config-wrapper usr/sbin
 * scripts/ubi-reload-keyboard /usr/lib/oem-config/post-install

**oem-config-remaster.install**

 * bin/oem-config-remaster usr/sbin

**oem-config-udeb.install**

 * finish-install.d usr/lib


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
 * ubiquity-dm vt7 :0 oem /usr/sbin/oem-config-wrapper --only

## Utilities Usage

* For host
 * debug-init: Initialize host debugging environment and provide mount/umount/ssh commands to access target remotely.
* For target
 * debug-ubiquity.sh: Launch Ubiquity with proper debugging parameters.

## workflow

    # launch ubiquity
    host $ ./debug-init ssh
    targ $ ./debug-ubiquity.sh start &
    targ $ DISPLAY=:0 gnome-terminal &

    # modify ubiquity
    host $ vim mnt/<target file>

## Other Tips

* Print debugging messages directly via syslog.syslog().
* Use watch command to monitor syslog.
 * $ watch -n 1 tail -n 30 /var/log/syslog


# Code Flow

debian/ubiquity.ubiquity.upstart  # kernel parameter `automatic-ubiquity' in phase1 and phase2 

    ubiquity-dm
    `-- oem-config-wrapper
        |-- oem-config  # symbolic link of /usr/lib/ubiquity/bin/ubiquity
        |-- ubiquity (is /usr/bin/ubiquity an alias of ubiquity-wrapper?)
        |-- ubiquity (real one, but when/where to call it?)
        |   |-- # Set locale to UTF-8
        |   |-- # Parse CLI args
        |   |-- # Set environment variables
        |   |-- # Set proper authority
        |   |-- install
        |   |     `-- wizard.run
        |   |         |--  start -> process_input .
        |   |         |--  ok_handler             `-> debconffilter_done -> find_next_step
        |   |         `--  # 1. postinstall starts after all the questions are
        |   |              #    answered and slideshow appears.
        |   |              # 2. plugininstall.py is executed in postinstall phase.
        |   `-- run_oem_hooks
        |       |-- # If oem_config is True
        |       `-- # Run hook scripts in /usr/lib/oem-config/post-install
        `--  oem-config-remove-gtk  # Remove ubiquity-related packages


# Code Structure

## Components Relationship
                                      I                    I
                       UntrustedBase ---> plugin.PluginUI ---> PageBase ---> Page<frontend>
                             |
                             | I
                             v          I                  I
    DebconfFilter ---> FilteredCommand ---> plugin.Plugin .--> Page
                             |                            |                          I
                             | I                          `--> plugin.InstallPlugin ---> Install
                             v
             components.plugininstall.Install (dbfilter)
                             |
                             |
                             v
           Controller ---> Wizard
                             |
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
 * init(): sets up plugins.
 * run(): the main part.
  * Get user inputs via pages.
  * Postinstall with slideshow.
  * Quit/reboot/shutdown.
 * find_next_step():
 * debconffilter_done():

* Controller: Define the control in a plugin.

* FilteredCommand:
 * ok_handler(): when ok or forward is selected.
  * Triggered by GUI ok/forward button handler (on_next_clicked()). 
  * Execute frontend.debconffilter_done(). (entry point of postinstall?)

* DebconfFilter: Filte a debconf command from another process and execute it
 * Get a command from another process, check it with the valid_command, execute the valid command
 * Input:
  * db: DebconfCommunicator object
  * widgets: The dictionary whose keys are XXX and values are
             <plugin>.Page objects and plugininstall.Install.

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


# Ubiquity Plugins, More Information

Page<frontend> and Page
 * PageGtk will be executed to setup the GUI.
 * Page.run will be executed to enter main loop.
  * self.ui equals to the PageGtk instance?
  * However, dell-eula does not have Page and can work.  It seems not to be necessary.

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


# Glossary

widget
  GTK+ Widget?
