<!--
Markdown live preview: http://tmpvar.com/markdown.html
-->

# Execution Order of Ubiquity Plugins
 * language
 * prepare
 * wireless
 * partman
 * timezone
 * console-setup
 * usersetup
 * network
 * tasks
 * webcam

--------------------------------------------------------------------------------
# Ubiquity Greeter And OEM Mode

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

--------------------------------------------------------------------------------
# Debugging

* [Hacking on Ubiquity, the setup](http://agateau.com/2013/04/30/hacking-on-ubiquity-the-setup/)
* [Debugging Ubiquity](https://wiki.ubuntu.com/DebuggingUbiquity)
* [Ubiquity (kubuntu wiki)](https://wiki.kubuntu.org/Ubiquity)
* [Custimize Live Initrd](https://wiki.ubuntu.com/CustomizeLiveInitrd)

kernel commandline parameter

 * phase 1 & 2: automatic-ubiquity
 * phase 3: ubiquity-dm vt7 :0 oem /usr/sbin/oem-config-wrapper --only # ubiquity-dm <vt> <display> <username> <args of dm.run>

--------------------------------------------------------------------------------
# Code Flow

debian/ubiquity.ubiquity.upstart  # kernel parameter `automatic-ubiquity' in phase1 and phase2 

    ubiquity-dm
      oem-config-wrapper
        oem-config  # symbolic link of /usr/lib/ubiquity/bin/ubiquity
        ubiquity (is /usr/bin/ubiquity an alias of ubiquity-wrapper?)
        ubiquity (real one, but when/where to call it?)
          install
            wizard.run
          run_oem_hooks  # If oem_config is True.
                         # Run hook scripts from /usr/lib/oem-config/post-install.
        oem-config-remove-gtk  # Remove ubiquity-related packages


--------------------------------------------------------------------------------
# Ubiquity Plugin

https://wiki.ubuntu.com/Ubiquity/Plugins

I guess
 * PageGtk will be executed to setup the GUI.
 * Page.run will be executed to enter main loop.
  * self.ui equals to the PageGtk instance?
  * However, dell-eula does not have Page and can work.  It seems not to be necessary.

Plugin Structure

    from ubiquity import plugin
    plugin.PluginUI
      PageBase
        PageGtk
        PageKde
        PageNoninteractive
          __init__
          set_language
          get_language
        PageDebconf
          __init__
    
    plugin.Plugin
      Page
        prepare
        run
        cancel_handler
        ok_handler
        cleanup
    
    # Perform install-time work
    plugin.InstallPlugin
      Install
        prepare (optional)
        install

--------------------------------------------------------------------------------
# Code Structure

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
    
    [Components]
    class Wizard(BaseFrontend):
      # Primary structure of GUI.  Collecte system configs from user
    
      self.modules  # list containing ordered plugins
      self.pages    # list containing configured modules in the module list (self.modules)
    
      def run()
    
      def find_next_step():
        # end of collecting system configs
        if finished_step == last_page:
          dbfilter = plugininstall.Install(self)
          dbfilter.start(auto_process=True)
    
    class Controller
       # Define actions of a plugin.  <plugin>.controller
    
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


