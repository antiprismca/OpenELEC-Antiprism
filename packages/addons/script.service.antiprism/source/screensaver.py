import sys
import xbmcaddon
import xbmcgui
import xbmc
import time

Addon = xbmcaddon.Addon('script.service.antiprism')

__scriptname__ = Addon.getAddonInfo('name')
__path__ = Addon.getAddonInfo('path')

class Screensaver(xbmcgui.WindowXMLDialog):

	class ExitMonitor(xbmc.Monitor):

		def __init__(self, exit_callback):
			self.exit_callback = exit_callback

		def onScreensaverDeactivated(self):
			self.exit_callback()

	def onInit(self):
		self.monitor = self.ExitMonitor(self.exit)

	def exit(self):
		xbmc.executebuiltin('RunScript("' + __path__ + '/default.py","password")')
		time.sleep(1)
		self.close()

if __name__ == '__main__':
	screensaver_gui = Screensaver(
	   'script-antiprism-screensaver.xml',
	   __path__,
	   'Default',
	)
	screensaver_gui.doModal()
	del screensaver_gui.monitor
	del screensaver_gui
	sys.modules.clear()

