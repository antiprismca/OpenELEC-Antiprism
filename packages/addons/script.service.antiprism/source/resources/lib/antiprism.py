# -*- coding: utf-8 -*-
#########################################################################################
# Copyright (c) 2014-2015, AntiPrism.ca
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of
# conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list of
# conditions and the following disclaimer in the documentation and/or other materials
# provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be used
# to endorse or promote products derived from this software without specific prior written
# permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#########################################################################################

import xbmc, xbmcgui, xbmcaddon
import re, os, shutil, sys, time
import subprocess, random, tempfile, threading

__addon__ = xbmcaddon.Addon(id='script.service.antiprism')
T = __addon__.getLocalizedString

ON = "true"
OFF = "false"

ACTION_UNDEFINED = 0
ACTION_CREATE_CONTAINER = 1
ACTION_CREATING_CONTAINER = 2 
ACTION_COMPLETING_CONTAINER = 3 
ACTION_MOUNT_CONTAINER = 4 
ACTION_MAIN_MENU = 5

def ERROR(message):
	errtext = sys.exc_info()[1]
	print 'ANTIPRISM - %s::%s (%d) - %s' % (message, sys.exc_info()[2].tb_frame.f_code.co_name, sys.exc_info()[2].tb_lineno, errtext)
	return str(errtext)
	
def LOG(message):
	print 'ANTIPRISM: %s' % str(message)

def clearDirFiles(filepath):
	if not os.path.exists(filepath): return
	for f in os.listdir(filepath):
		f = os.path.join(filepath, f)
		if os.path.isfile(f): os.remove(f)

def doKeyboard(prompt, default='', hidden=False, sec_autoclose=0):
	keyboard = xbmc.Keyboard(default, prompt)
	keyboard.setHiddenInput(hidden)
	if sec_autoclose > 0: 
		keyboard.doModal(sec_autoclose)
	else:
		keyboard.doModal()
	if not keyboard.isConfirmed(): return None
	return keyboard.getText()

def GetPortValue(conffile, value, default):
	ret = default
	try:
		with open(conffile, "rt") as f:
			for line in f:
				values = line.split("=")
				if values[0] == value:
					ret = int(values[1])
					break
	except:
		ret = default	
	return str(ret)

ANTIPRISM_BIN = os.path.join(__addon__.getAddonInfo('path'), 'bin')
CRYPTO_HELPER = LUKS_HELPER = 'ANTIPRISM=1 ' + ANTIPRISM_BIN + '/cryptsetup.sh'
if __addon__.getSetting('use_truecrypt') == 'true':
	TC_ADDON = xbmcaddon.Addon(id='plugin.program.truecrypt')
	TC_HELPER = os.path.join(TC_ADDON.getAddonInfo('path'), 'bin', 'truecrypt.sh')
	CRYPTO_HELPER = 'ANTIPRISM=1 ' + TC_HELPER
OBFSPROXY = "/usr/bin/obfsproxy"
OBFS4PROXY = "/usr/bin/obfs4proxy"

shellCharsToBeEscaped = ["$", "\"", "\\", "`"]
def escapeCharsForShell(string):
	"""Method escapes special characters in string to be used in linux shell."""
	tempStr = ""

	for a in string:
		for i in range(0, len(shellCharsToBeEscaped)):
			if a == shellCharsToBeEscaped[i]:
				tempStr = tempStr + "\\" + a
				break
			if i == (len(shellCharsToBeEscaped) -1):
				tempStr = tempStr + a
	return tempStr

######################################################################################
# File Size Checker
######################################################################################
class FileSizeChecker(threading.Thread):

	def __init__(self, file, callback):
		self.file = file
		self.callback = callback
		threading.Thread.__init__(self)

	def run(self):
		ret = True
		while ret: 
			time.sleep(1)
			st = None
			try:
				st = os.stat(self.file)
			except:
				pass
			if st != None:
				ret = self.callback(st.st_size)
			else:
				ret = self.callback(0)

######################################################################################
# AntiPrism Container
######################################################################################
class AntiPrismContainer():

	def __init__(self):
		self.output = ""
		self.errors = ""

	def Mounted(self, container="", path=""):
		cmd = CRYPTO_HELPER  + " "
		cmd += "\"ismounted\" "
		if container == "":
			container = __addon__.getSetting('container')
		if path == "":
			path = __addon__.getSetting('mountpoint')
		cmd += "\"" + container + "\" "
		cmd += "\"" + path + "\""
		return subprocess.call(cmd, shell=True) == 0

	def CreateContainer(self, size, password):
		cmd = CRYPTO_HELPER  + " "
		cmd += "\"create\" "
		cmd += "\"" + __addon__.getSetting('container') + "\" "
		cmd += "\"" + __addon__.getSetting('mountpoint') + "\" "
		cmd += "\"\" "
		cmd += "\"" + str(size) + "\" \"" + __addon__.getSetting('filesystem') + "\""
		p = subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
		self.output, self.errors = p.communicate(input = escapeCharsForShell(password)+"\n")
		return p.returncode == 0

	def ChangePassword(self, old_password, new_password):
		cmd = CRYPTO_HELPER  + " "
		cmd += "\"changepass\" "
		cmd += "\"" + __addon__.getSetting('container') + "\" "
		cmd += "\"\" "
		cmd += "\"\" "
		p = subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
		self.output, self.errors = p.communicate(input = escapeCharsForShell(old_password)+"\n"+escapeCharsForShell(new_password)+"\n")
		return p.returncode == 0

	def MountContainer(self, password, container="", mountpoint="", options="", buffer_towrite="", file_towrite="", ssh_password=""):
		cmd = ""
		if __addon__.getSetting('use_ram') != "true" and __addon__.getSetting('hidden_website') == "true" and __addon__.getSetting('use_jetty') == "true":
			cmd += 'ANTIPRISM_WEBSITE=1 '
		if buffer_towrite != "":
			cmd += 'ANTIPRISM_WRITE_BUFFER="' + buffer_towrite + '" '
		if file_towrite != "":
			cmd += 'ANTIPRISM_WRITE_FILE="' + file_towrite + '" '	
		cmd += CRYPTO_HELPER  + " "
		cmd += "\"mount\" "
		if container == "":
			container = __addon__.getSetting('container')
		cmd += "\"" + container + "\" "
		if mountpoint == "":
			mountpoint = __addon__.getSetting('mountpoint')
		cmd += "\"" + mountpoint + "\" "
		cmd += "\"\" \"\" \"" + __addon__.getSetting('filesystem') + "\" \"" + options + "\""
		p = subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
		if ssh_password != "":
			ssh_password = escapeCharsForShell(ssh_password) + "\n"
		self.output, self.errors = p.communicate(input = escapeCharsForShell(password)+"\n"+ssh_password)
		return p.returncode == 0

	def UnmountContainer(self, container="", mountpoint=""):
		cmd = CRYPTO_HELPER  + " "
		cmd += "\"dismount\" "
		if container == "":
			container = __addon__.getSetting('container')
		cmd += "\"" + container + "\" "
		if mountpoint == "":
			mountpoint = __addon__.getSetting('mountpoint')
		cmd += "\"" + mountpoint + "\""
		p = subprocess.Popen(cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE, shell=True)
		self.output, self.errors = p.communicate()
		return p.returncode == 0

	def CheckContainer(self, password):
		cmd = CRYPTO_HELPER  + " "
		cmd += "\"check\" "
		cmd += "\"" + __addon__.getSetting('container') + "\" "
		options="-p"
		if __addon__.getSetting('filesystem') == "ntfs":
			options = "-b -d"
		cmd += "\"\" \"" + __addon__.getSetting('filesystem') + "\" \"" + options + "\""
		p = subprocess.Popen(cmd,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
		self.output, self.errors = p.communicate(input = escapeCharsForShell(password)+"\n")
		return p.returncode == 0

######################################################################################
# AntiPrism Password Window
######################################################################################
class AntiPrismPasswordWindow(xbmcgui.WindowXML):
	def __init__(self, *args, **kwargs):
		self.container = None
		xbmcgui.WindowXML.__init__(self)

	def onInit(self):
		self.container = AntiPrismContainer()
		if __addon__.getSetting('pwdscreen') == 'true' and self.container.Mounted():
			pwd = doKeyboard(T(32012), "", True, 30)
			if pwd != None and pwd != "":
				mnt_point = tempfile.mkdtemp()
				cnt = __addon__.getSetting('container')
				lnk = cnt + "___"
				try:
					os.symlink(cnt, lnk)
				except:
					pass
				time.sleep(1)
                        	if self.container.MountContainer(pwd, lnk, mnt_point, "readonly"):
                        	        self.container.UnmountContainer(lnk, mnt_point)
                        	        os.rmdir(mnt_point)
                        	        os.unlink(lnk)
                        	        del self.container
					self.container = None
                        	        self.close()
                        	        return
				try:
                        		os.rmdir(mnt_point)
				except:
					pass
				try:
                        		os.unlink(lnk)
				except:
					pass
                	xbmc.executebuiltin('ActivateScreensaver()')
			time.sleep(1)
		del self.container
		self.container = None
                self.close()

######################################################################################
# AntiPrism Window
######################################################################################
class AntiPrismWindow(xbmcgui.WindowXML):
	IS_DIALOG = False
	def __init__(self, *args, **kwargs):
		self.first = True
		self.password1 = ''
		self.password2 = ''
		self.old_password = ''
		self.ssh_password = ''
		self.size = 0
		self.restore_file = None
		self.restore_password = None
		self.action = ACTION_UNDEFINED
		self.container = None
		self.anonymized = False
		xbmcgui.WindowXML.__init__(self)

	def backendInit(self):
		random.seed()
		if int(__addon__.getSetting('tor_obfs2port')) == -1:
			__addon__.setSetting('tor_obfs2port', str(random.randint(1024, 65534)))
		if int(__addon__.getSetting('tor_obfs3port')) == -1:
			__addon__.setSetting('tor_obfs3port', str(random.randint(1024, 65534)))
		if int(__addon__.getSetting('tor_obfs4port')) == -1:
			__addon__.setSetting('tor_obfs4port', str(random.randint(1024, 65534)))
		
	def onInit(self):
		self.backendInit()
		if self.container is None:
			self.container = AntiPrismContainer()
		self.getControl(32098).setLabel(T(32098))
		self.getControl(32099).setLabel(T(32099))
		self.getControl(32100).setLabel(T(32100))
		self.getControl(32101).setLabel(T(32101))
		self.getControl(32102).setLabel(T(32174))
		self.HIDE( [ 1003, 1008, 1010, 1015, 1100, 1200, 1300, 1400 ] )
		self.getControl(1001).setLabel(T(32010))

		if not os.path.exists(__addon__.getSetting('container')):
			self.SHOW( [ 1002 ] )
                	self.getControl(1002).setLabel(T(32011))
			self.action = ACTION_CREATE_CONTAINER
		elif not self.container.Mounted():
			if self.action != ACTION_COMPLETING_CONTAINER:
				self.SHOW( [ 1003, 1008, 1010 ] )
				self.getControl(1003).setLabel(T(32120))
				self.setFocus(self.getControl(1008))
				self.action = ACTION_MOUNT_CONTAINER
			else:
				self.SHOW( [ 1002, 1015 ] )
				self.getControl(1001).setLabel(T(32168))
				self.getControl(1002).setLabel(T(32024))
		else:
			self.action = ACTION_MAIN_MENU
			self.DisplayMenu()

		if not self.first: return
		self.first = False
		
	def onFocus(self, controlId):
		self.controlId = controlId

	def ContainerSizeUpdate(self, size):
		if self.action != ACTION_CREATING_CONTAINER:
			return False
		if size > 0:
			perc = int(100. * size / self.size)
			if perc < 100:
				self.getControl(1002).setLabel(T(32034) + str(perc) +"%")
			else:
				self.getControl(1002).setLabel(T(32034) + T(32118))
		return True
		
	def onClick(self, controlID):
		global CRYPTO_HELPER
		if controlID == 200:
			if self.action == ACTION_CREATE_CONTAINER:
				self.HIDE( [ 1001, 1002 ] )
				st = os.statvfs(os.path.dirname(__addon__.getSetting('container')))
				free = st.f_bavail * st.f_frsize
				perc = 90
				while True:
					inp = doKeyboard(T(32123), str(perc))
					if inp == None:
						self.close()
						return
					try:
						perc = int(inp)
					except:
						perc = 0
					self.size = free * perc / 100
					if self.size > 50 * 1024 * 1024:
						break
					if perc == 100:
						xbmcgui.Dialog().ok(T(32109),T(32110))
						self.close()
						return
					xbmcgui.Dialog().ok(T(32111),T(32112))
			
				if not self.GetNewPassword():
					self.close()
					return	
	
				self.getControl(1001).setLabel(T(32115))
				sz = str(self.size / 1048576) + " Mb"
				self.getControl(1002).setLabel(T(32116) + sz + "\n" + T(32117))
				self.SHOW( [ 1001, 1002 ] )
				self.action = ACTION_CREATING_CONTAINER

			elif self.action == ACTION_CREATING_CONTAINER:
				err = ""
				self.HIDE( [200, 202, 204, 206, 208, 1003, 1008, 1010, 1020, 32098, 32099, 32100, 32101, 32102] )
				self.SHOW( [ 1001, 1002 ] )
				self.getControl(1001).setLabel(T(32027))
				self.getControl(1002).setLabel(T(32034))
				t = FileSizeChecker(__addon__.getSetting('container'), self.ContainerSizeUpdate)
				t.start()
				if self.container.CreateContainer(self.size, self.password1):
					self.action = ACTION_COMPLETING_CONTAINER
				else:
					err = str(self.container.errors)
				self.SHOW( [200, 202, 204, 206, 208, 32098, 32099, 32100, 32101, 32102] )
				if self.action == ACTION_COMPLETING_CONTAINER:
					self.SHOW( [ 1001, 1002, 1015 ] )
					self.getControl(1001).setLabel(T(32168))
					self.getControl(1002).setLabel(T(32024))
					return
				else:
					self.HIDE( [ 1001 ] )
					xbmcgui.Dialog().ok(T(32015),err)
					# self.action = ACTION_CREATE_CONTAINER
					# self.onClick(200)
					self.close()
			
			elif self.action == ACTION_MOUNT_CONTAINER or self.action == ACTION_COMPLETING_CONTAINER:
				self.HIDE( [ 1002, 1003, 1008, 1010, 1015 ] )
				if self.action == ACTION_MOUNT_CONTAINER:
					if not self.GetPassword():
						self.close()
						return
				if __addon__.getSetting('enable_ssh') == "true":
					os.environ["ANTIPRISM_NOSSH"] = ""
					if not os.path.exists("/storage/.cache/ssh/password"):
						while True:
							self.ssh_password = doKeyboard(T(32207), '', True)
							if self.ssh_password != self.password1:
								break
							xbmcgui.Dialog().ok(T(32015), T(32208))
						if self.ssh_password == "":
							os.environ["ANTIPRISM_NOSSH"] = "1"
				else:
					os.environ["ANTIPRISM_NOSSH"] = "1"

				self.getControl(1001).setLabel(T(32032))
				if self.StartAntiPrism():
					self.action = ACTION_MAIN_MENU
					self.DisplayMenu()
				else:
					xbmcgui.Dialog().ok(T(32015), T(32119))
					self.close()
			else:
				self.close()

		elif controlID == 202:
			if self.action == ACTION_MAIN_MENU:
				if xbmcgui.Dialog().yesno(T(32102), T(32103)):
					self.StopAntiPrism()
					self.close()
			else:
				self.close()

		elif controlID == 1008:
			self.onClick(200)
			return

		elif controlID == 1010:
			self.HIDE( [ 1002, 1003, 1008, 1010 ] )
			if not self.GetPassword():
				self.close()
				return
			pwd = self.password1
			if not self.GetNewPassword():
				self.close()
				return

			self.SHOW( [ 1001, 1002 ] )
			self.getControl(1001).setLabel(T(32121))
			self.getControl(1002).setLabel(T(32034))

			self.HIDE( [200, 202, 204, 206, 208, 32098, 32099, 32100, 32101, 32102] )
			if self.container.ChangePassword(pwd, self.password1):
				self.action = ACTION_COMPLETING_CONTAINER
			else:
				err = str(self.container.errors)
			self.HIDE( [ 1001 ] )
			self.SHOW( [200, 202, 204, 206, 208, 32098, 32099, 32100, 32101, 32102] )
			if self.action == ACTION_COMPLETING_CONTAINER:
				self.SHOW( [ 1002 ] )
				self.getControl(1002).setLabel(T(32122))
			else:
				self.HIDE( [ 1002 ] )
				xbmcgui.Dialog().ok(T(32015),err)
				self.close()

		elif controlID == 1015:
			dialog = xbmcgui.Dialog()
			self.restore_file = dialog.browseSingle(1, T(32166), 'files')
			if self.restore_file != None:
				self.restore_password = doKeyboard(T(32014), '', True)
			self.onClick(200)

		elif controlID == 206:
			tor_rules = self.GetTorRules()
			firewall_rules = self.GetFirewallRules()
			use_ram = __addon__.getSetting('use_ram')
			enable_tor = __addon__.getSetting('enable_tor')
			enable_i2p = __addon__.getSetting('enable_i2p')
			enable_privoxy = __addon__.getSetting('enable_privoxy')
			route_from = __addon__.getSetting('tor_routefrom')
			p = subprocess.Popen("for f in " + __addon__.getSetting('mountpoint') + "/.ssh/*key.pub; do ssh-keygen -lf $f 2>/dev/null; done | cut -d' ' -f2 | tr '\n' ','", stdout=subprocess.PIPE,stderr=subprocess.PIPE, shell=True)
			output, errors = p.communicate()
			fingerprint = str(output)
			if __addon__.getSetting('ssh_fingerprint') != fingerprint:
				__addon__.setSetting('ssh_fingerprint', fingerprint)
			__addon__.openSettings()
			if __addon__.getSetting('use_truecrypt') == 'true':
				TC_ADDON = xbmcaddon.Addon(id='plugin.program.truecrypt')
				TC_HELPER = os.path.join(TC_ADDON.getAddonInfo('path'), 'bin', 'truecrypt.sh')
				CRYPTO_HELPER = 'ANTIPRISM=1 ' + TC_HELPER
			else:
				CRYPTO_HELPER = LUKS_HELPER = 'ANTIPRISM=1 ' + ANTIPRISM_BIN + '/cryptsetup.sh'
			if self.GetTorRules() != tor_rules or self.GetFirewallRules() != firewall_rules or use_ram != __addon__.getSetting('use_ram') or enable_tor != __addon__.getSetting('enable_tor') or enable_i2p != __addon__.getSetting('enable_i2p') or enable_privoxy != __addon__.getSetting('enable_privoxy') or route_from != __addon__.getSetting('tor_routefrom'):
				xbmcgui.Dialog().ok(T(32185), T(32186))

		elif controlID == 1100 or controlID == 204:
			if __addon__.getSetting('enable_privoxy') == 'true':
				proxy_string = "-http-proxy 127.0.0.1:8118 -https-proxy 127.0.0.1:8118"
				homepage = "index.html"
			elif __addon__.getSetting('enable_tor') == 'true':
				proxy_string = "-socks-proxy 127.0.0.1:" + __addon__.getSetting('tor_socksport')
				homepage = "index2.html"
			elif __addon__.getSetting('enable_i2p') == 'true':
				proxy_string = "-http-proxy 127.0.0.1:4444 -https-proxy 127.0.0.1:4445"
				homepage = "index3.html"
			else:
				xbmcgui.Dialog().ok(T(32191), T(32192))
				return
			if controlID == 1100:
				hp_path = os.path.join(__addon__.getAddonInfo("path"), "resources", "language", xbmc.getLanguage(), homepage)
				if not os.path.exists(hp_path):
					hp_path = os.path.join(__addon__.getAddonInfo("path"), "resources", "language", "English", homepage)
				if not os.path.exists(hp_path):
					hp_path = ""
			else:
				hp_path = os.path.join(__addon__.getAddonInfo("path"), "resources", "language", xbmc.getLanguage(), "manual.html")
				if not os.path.exists(hp_path):
					hp_path = os.path.join(__addon__.getAddonInfo("path"), "resources", "language", "English", "manual.html")
		
			links_lng = xbmc.getLanguage()	
			if links_lng not in [ "English", "Bahasa Indonesian", "Belarusian", "Brazilian Portuguese", "Bulgarian", "Catalan", "Croatian", "Czech", "Danish", "Dutch", "Estonian", "Finnish", "French", "Galician", "German" , "Greek", "Hungarian", "Icelandic", "Italian", "Lithuanian", "Norwegian", "Polish", "Portuguese", "Romanian", "Russian", "Serbian", "Slovak", "Spanish", "Swedish", "Swiss German", "Turkish", "Ukrainian", "Upper Sorbian" ]:
				links_lng = "English"
			links_file = "/usr/bin/links" 
			if not os.path.isfile(links_file) or not os.access(links_file, os.X_OK) or subprocess.call("HOME=\"" + __addon__.getSetting("mountpoint") + "\" " + links_file + " -menu-background-color 0xFF0000 -mode "+str(self.getWidth())+"x"+str(self.getHeight())+" -language \""+links_lng+"\" -only-proxies 1 " + proxy_string + " \"" + hp_path + "\" &", shell=True) != 0:
				# Links did not work - try WebViewer addon
				if self.anonymized:
					xbmc.executebuiltin("XBMC.RunScript(/usr/share/kodi/addons/script.web.viewer/lib/webviewer/webviewer.py,file://" + hp_path + ")") 
				else:
					xbmcgui.Dialog().ok(T(32015),T(32195))

		elif controlID == 1200:
			try:
				ad = xbmcaddon.Addon(id='plugin.program.i2p')	
				self.close()
				xbmc.executebuiltin("XBMC.ActivateWindow(programs,plugin://plugin.program.i2p/?index=0&homepath=" + __addon__.getSetting("mountpoint") + ")")
			except:
				xbmcgui.Dialog().ok(T(32015),T(32227))

		elif controlID == 1300:
			try:
				ad = xbmcaddon.Addon(id='plugin.program.gnupg')
				self.close()
				xbmc.executebuiltin("XBMC.ActivateWindow(programs,plugin://plugin.program.gnupg/?homepath=" + __addon__.getSetting("mountpoint") + ")")
			except:
				xbmcgui.Dialog().ok(T(32015),T(32227))

		elif controlID == 1400:
			try:
				ad = xbmcaddon.Addon(id='plugin.program.i2p')
				self.close()
				xbmc.executebuiltin("XBMC.ActivateWindow(programs,plugin://plugin.program.i2p/?index=1&homepath=" + __addon__.getSetting("mountpoint") + ")")
			except:
				xbmcgui.Dialog().ok(T(32015),T(32227))

		elif controlID == 208:
			if __addon__.getSetting('use_xterm') == 'true':
				subprocess.call("HISTFILE=\"\" PS1=\"\\u@\\h:\\w\\# \" /usr/bin/urxvt -geometry 168x46 -foreground white -background black -e \"/bin/sh\" &", shell=True)
			else:
				cmd = doKeyboard(T(32026), '')
				if cmd != "":
					p = subprocess.Popen("HISTFILE=\"\" " + cmd, stdout=subprocess.PIPE,stderr=subprocess.PIPE, shell=True)
					output, errors = p.communicate()
					xbmcgui.Dialog().ok(T(32025), str(output)+'\n'+str(errors))

	def GetPassword(self):
		self.password1 = doKeyboard(T(32012), '', True)
		if self.password1 == None: return False
		return True

	def GetNewPassword(self):
		while True:
			self.password1 = doKeyboard(T(32124), '', True)
			if self.password1 == None:
				return False
			if len(self.password1) > 19:
				break
			if len(self.password1) > 12 and xbmcgui.Dialog().yesno('', T(32108)):
				break;	
			xbmcgui.Dialog().ok('', T(32126))

		while True:
			self.password2 = doKeyboard(T(32125), '', True)
			if self.password2 == None:
				return False
			if self.password1 != self.password2:
				xbmcgui.Dialog().ok(T(32113),T(32114))
			else:
				break
		return True

	def runTor(self):
		try:
			tor_path = __addon__.getSetting('mountpoint')
			if __addon__.getSetting('use_ram') == "true":
				tor_path = "/var/run"
			cmd = "PROFILE_PATH=\"" + tor_path + "\" /usr/bin/tor & "
			return subprocess.call(cmd, shell=True)
		except:
			return -1

	def StartAntiPrism(self):
		mounted = self.container.Mounted()
		if not mounted:
			if not os.path.exists(__addon__.getSetting('mountpoint')):
				try:
					os.makedirs(__addon__.getSetting('mountpoint'))
				except:
					return False

			if os.path.exists(__addon__.getSetting('mountpoint') + '/*.*'):
				if xbmcgui.Dialog().yesno(T(32104), T(32105)):
					try:
						clearDirFiles(__addon__.getSetting('mountpoint') + "/*.*")
					except:
						return False

			if __addon__.getSetting('runfsck') == 'true':
				self.getControl(1001).setLabel(T(32035))
				self.container.CheckContainer(self.password1)
				err = str(self.container.output)
				if err == "":
					err = str(self.container.errors)
				if err != "":
					xbmcgui.Dialog().ok(T(32025), err)
				# self.getControl(1001).setLabel(T(32032))
			os.environ["ANTIPRISM_IPTABLES"] = self.GetFirewallRules()
			# fl = open("/storage/fw.rules", "w")
			# fl.write(os.environ["ANTIPRISM_IPTABLES"])
			# fl.close()
			tor_path = __addon__.getSetting('mountpoint')            
			if __addon__.getSetting('use_ram') == "true":                  
				tor_path = "/var/run"
			mounted = self.container.MountContainer(self.password1, "", "", "", self.GetTorRules(), tor_path + "/.torrc", self.ssh_password)
			os.environ["ANTIPRISM_IPTABLES"] = ""
			err = str(self.container.errors)
		if mounted:
			err = ""
			if self.restore_file != None and self.restore_password != None:
                                self.getControl(1001).setLabel(T(32167))
                                p = subprocess.Popen(ANTIPRISM_BIN + "/restore_profile.sh \"" + __addon__.getSetting('mountpoint') + "\" \"" + self.restore_file + "\"",stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
                                output, errors = p.communicate( input = self.restore_password )
                                if p.returncode != 0:
                                        err = errors
				self.restore_file = None
				self.restore_password = None

			if not os.path.exists(__addon__.getSetting('mountpoint') + "/i2p"):
				try:
					plugin_dist_dir = '/usr/lib/i2p/dist-plugins'
					if os.path.exists(plugin_dist_dir):
						shutil.copytree(plugin_dist_dir, __addon__.getSetting('mountpoint') + "/i2p")
					else:
						os.makedirs(__addon__.getSetting('mountpoint') + "/i2p")
				except:
					pass

			if not os.path.exists("/var/log/privoxy"):
				try:
					os.makedirs("/var/log/privoxy")
				except:
					pass

			if __addon__.getSetting('runbackup') == 'true':
				self.getControl(1001).setLabel(T(32036))
				backupFilePath = __addon__.getSetting('backup_path') + "/backup_file.dat"
				# backup file rotation
				try:
					oldBackupFilePath = __addon__.getSetting('backup_path') + "/backup_file.old"
					if os.path.exists(oldBackupFilePath):
						os.unlink(oldBackupFilePath)
					os.rename(backupFilePath, oldBackupFilePath)
				except:
					pass
				
				p = subprocess.Popen(ANTIPRISM_BIN + "/backup_profile.sh \"" + __addon__.getSetting('mountpoint') + "\" \"" + backupFilePath + "\"", stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
				output, errors = p.communicate()
				if p.returncode != 0:
					err = err + "\n" + errors

			self.getControl(1001).setLabel(T(32032))

			# Start daemons
			if __addon__.getSetting('enable_tor') == "true":
				if __addon__.getSetting('use_ram') != "true" and __addon__.getSetting('logging') == "true":
					# log rotation
					try:
						if os.path.exists(__addon__.getSetting('mountpoint') + "/tor.log.old"):
							os.unlink(__addon__.getSetting('mountpoint') + "/tor.log.old")
						os.rename(__addon__.getSetting('mountpoint') + "/tor.log", __addon__.getSetting('mountpoint') + "/tor.log.old")
					except:
						pass

				returnCode = self.runTor();
				if returnCode != 0:
					err = err + "\n" + T(32028)
				else:
					if __addon__.getSetting('tor_router') == "true":
						subprocess.call("cp /etc/resolv.conf /tmp/resolv.conf.bkp", shell=True)
						subprocess.call("echo \"nameserver 127.0.0.1\" > /etc/resolv.conf", shell=True)

			if __addon__.getSetting('enable_i2p') == "true":
				use_proxy = ""
				if __addon__.getSetting('i2p_via_tor') == "true":
					use_proxy = " USE_PROXY=1 "
				use_log = ""
				if __addon__.getSetting('use_ram') != "true" and __addon__.getSetting('logging') == "true":
					use_log = " USE_LOG=1 "

				i2p_path = __addon__.getSetting('mountpoint')
				if __addon__.getSetting('use_ram') == "true":
					i2p_path = "/var/run"
				returnCode = subprocess.call("I2PCONFIG=\"" + i2p_path  + "\" I2PTEMP=\"" + i2p_path + "\"" + use_proxy + use_log + " i2p-runplain", shell=True)
				if returnCode != 0:
					err = err + "\n" + T(32029)

			if __addon__.getSetting('use_ram') != "true" and __addon__.getSetting('hidden_website') == "true" and __addon__.getSetting('enable_tor') == "true" and __addon__.getSetting('use_hiawatha') == "true":
				# Launch hiawatha on port 8080
				returnCode = subprocess.call("hiawatha -c \"" + __addon__.getSetting('mountpoint') + "/.hiawatha\"", shell=True)
				if returnCode != 0:
					err = err + "\n" + T(32225)

			if __addon__.getSetting('enable_tor') == "true" and __addon__.getSetting('enable_privoxy') == "true":
				returnCode = subprocess.call("privoxy /etc/privoxy/config", shell=True)
				if returnCode != 0:
					err = err + "\n" + T(32197)
				else:
					os.environ["http_proxy"] = "127.0.0.1:8118"

			if __addon__.getSetting('enable_vpn') == "true":
				returnCode = subprocess.call("openvpn --cd \"" + __addon__.getSetting('mountpoint') + "/.openvpn\" --config config --log-append openvpn.log &", shell=True)
				if returnCode != 0:                                        
					err = err + "\n" + T(32198)

		if err != "":
			xbmcgui.Dialog().ok(T(32015), err)
			return False

		return True

	def StopAntiPrism(self):
		self.HIDE( [200, 202, 204, 206, 208, 1002, 1003, 1100, 1200, 1300, 1400, 32098, 32099, 32100, 32101, 32102] )
		self.getControl(1001).setLabel(T(32030))

		# Stop daemons
		subprocess.call("killall links && while pidof links ; do sleep 1; killall -g links; done; sync", shell=True)
		subprocess.call("killall privoxy && while pidof privoxy ; do sleep 1; killall -g privoxy; done; sync", shell=True)
		subprocess.call("killall tor && while pidof tor ; do sleep 1; killall -g tor; done; sync", shell=True)
		subprocess.call("killall java && while pidof java ; do sleep 1; killall -g java; done; sync", shell=True)
		subprocess.call("killall openvpn && while pidof openvpn ; do sleep 1; killall -g openvpn; done; sync", shell=True)
		subprocess.call("killall hiawatha && while pidof hiawatha ; do sleep 1; killall -g hiawatha; done; sync", shell=True)
		clearDirFiles(__addon__.getSetting('mountpoint') + "/i2p/i2p*.tmp")
		subprocess.call("cat /tmp/resolv.conf.bkp > /etc/resolv.conf", shell=True)

		# Unmount
		rules =  "-F\\n"
		rules += "-t nat -F\\n"
		rules += "-A FORWARD -j DROP\\n"
		rules += "-A INPUT -i lo -j ACCEPT\\n"
		rules += "-A INPUT -p icmp --icmp-type any -j ACCEPT\\n"
		rules += "-A INPUT -p udp --dport 67:68 --sport 67:68 -j ACCEPT\\n"
		rules += "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\\n"
		rules += "-A INPUT -j DROP\\n"
		os.environ["ANTIPRISM_IPTABLES"] = rules
		if not self.container.UnmountContainer():
			os.environ["ANTIPRISM_IPTABLES"] = ""
			xbmcgui.Dialog().ok(T(32015), str(self.container.errors))
			return False
		os.environ["ANTIPRISM_IPTABLES"] = ""
		os.environ["HTTP_PROXY"] = ""
		return True

	def DisplayMenu(self):
		self.SHOW( [200, 202, 204, 206, 208, 1001, 1003, 1100, 1200, 1300, 1400, 32098, 32099, 32100, 32101, 32102] )
		self.getControl(1001).setLabel(T(32031))
		guisettings = " $HOME/.kodi/userdata/guisettings.xml >/dev/null"
		if (subprocess.call("grep '>127.0.0.1</httpproxyserver>'" + guisettings, shell=True) == 0 or subprocess.call("grep '>localhost</httpproxyserver>'" + guisettings, shell=True) == 0) and subprocess.call("grep '>true</usehttpproxy>'" + guisettings, shell=True) == 0:
			self.getControl(1003).setLabel(T(32194) + "\n" + T(32175))
			self.anonymized = True
		else:
			if __addon__.getSetting('tor_router') == "true":
				self.getControl(1003).setLabel(T(32226) + "\n" + T(32175))
				self.anonymized = True
			else:
				self.getControl(1003).setLabel(T(32195) + "\n" + T(32175))
				self.anonymized = False
		return True

	def GetTorRules(self):
		rules = ""
		rules += "SocksPort 0.0.0.0:" + __addon__.getSetting('tor_socksport') + "\\n"
		if __addon__.getSetting('tor_usebridges') == "true":
			if __addon__.getSetting('tor_usemeekbridge') == "true":
				# use Meek transport
				rules += "UseBridges 1\\n"
				rules += "Bridge meek 0.0.2.0:1 url=https://meek-reflect.appspot.com/ front=www.google.com\\n"
				rules += "Bridge meek 0.0.2.0:2 url=https://d2zfqthxsdq309.cloudfront.net/ front=a0.awsstatic.com\\n"
				rules += "Bridge meek 0.0.2.0:3 url=https://az668014.vo.msecnd.net/ front=ajax.aspnetcdn.com\\n"
				rules += "ClientTransportPlugin meek exec /usr/bin/meek-client"
				if __addon__.getSetting('logging') == "true":
					rules += " --log " + __addon__.getSetting('mountpoint') + "/meek-client.log"
				rules += "\\n"
			else:
				bridges = __addon__.getSetting('tor_bridges')
				if bridges != "":
					rules += "UseBridges 1\\n"
					if __addon__.getSetting('tor_useobfs4bridge') == "true": 
						rules += "ClientTransportPlugin obfs2,obfs3,obfs4 exec " + OBFS4PROXY + "\\n"
					else:
						rules += "ClientTransportPlugin obfs2,obfs3 exec " + OBFSPROXY + " --managed\\n"
					for b in bridges.split(","):
						rules += ("Bridge " + b + "\\n")
	
		if __addon__.getSetting('tor_relay') == "true":
			if __addon__.getSetting('tor_bridgerelay') == "true":
				rules += "BridgeRelay 1\\n"
			rules += "ORPort " + __addon__.getSetting('tor_orport') + "\\n"
			rules += "ORListenAddress 0.0.0.0:" + __addon__.getSetting('tor_orlistenport') + "\\n"
			if __addon__.getSetting('tor_obfsproxy') == "true":
				transport = ""
				if __addon__.getSetting('tor_obfs2on') == "true":
					transport += "obfs2"
					rules += "ServerTransportListenAddr obfs2 0.0.0.0:" + __addon__.getSetting('tor_obfs2port') + "\\n"
				if __addon__.getSetting('tor_obfs3on') == "true":
					if transport != "":
						transport += ","
					transport += "obfs3"
					rules += "ServerTransportListenAddr obfs3 0.0.0.0:" + __addon__.getSetting('tor_obfs3port') + "\\n"
				if __addon__.getSetting('tor_obfs4on') == "true" and __addon__.getSetting('tor_obfs4proxy') == "true":
					if transport != "":
						transport += ","
					transport += "obfs4"
					rules += "ServerTransportListenAddr obfs4 0.0.0.0:" + __addon__.getSetting('tor_obfs4port') + "\\n"
				if transport != "":
					if __addon__.getSetting('tor_obfsproxy') == "true":
						rules += "ServerTransportPlugin " + transport + " exec " + OBFSPROXY + " --managed\\n"
					else:
						rules += "ServerTransportPlugin " + transport + " exec " + OBFS4PROXY + " --managed\\n"
		rules += "ExitPolicy reject *:*\\n"
		if __addon__.getSetting('tor_entrynodes'):
			rules += "EntryNodes " + __addon__.getSetting('tor_entrynodes') + "\\n"
		if __addon__.getSetting('tor_exitnodes'):
			rules += "ExitNodes " + __addon__.getSetting('tor_exitnodes') + "\\n"
		if __addon__.getSetting('tor_excludenodes'):
			rules += "ExcludeNodes " + __addon__.getSetting('tor_excludenodes') + "\\n"
		if __addon__.getSetting('tor_excludeexitnodes'):
			rules += "ExcludeExitNodes " + __addon__.getSetting('tor_excludeexitnodes') + "\\n"
		if __addon__.getSetting('logging') == "true":
			rules += "Log info file " + __addon__.getSetting('mountpoint') + "/tor.log\\n"
		if __addon__.getSetting('use_ram') != "true" and __addon__.getSetting('hidden_website') == "true":
			if __addon__.getSetting('enable_i2p') == "true" and __addon__.getSetting('use_jetty') == "true":
				rules += "HiddenServiceDir " + __addon__.getSetting('mountpoint') + "/i2p/eepsite/\\n"
				rules += "HiddenServicePort 80 127.0.0.1:7658\\n"
			if __addon__.getSetting('use_hiawatha') == "true":
				rules += "HiddenServiceDir " + __addon__.getSetting('mountpoint') + "/.hiawatha/\\n"
				rules += "HiddenServicePort 80 127.0.0.1:8080\\n"
		if __addon__.getSetting('tor_router') == "true":
			rules += "VirtualAddrNetworkIPv4 10.192.0.0/10\\n"
			rules += "AutomapHostsOnResolve 1\\n"
			rules += "TransPort 0.0.0.0:9040\\n"
			rules += "DNSPort 0.0.0.0:53\\n"
		return rules

	def IsTethering(self):
		p = subprocess.Popen("grep \"Tethering=true\" /storage/.cache/connman/settings > /dev/null", stdout=subprocess.PIPE,stderr=subprocess.PIPE, shell=True)
		output, errors = p.communicate()
		return p.returncode == 0

	def GetFirewallRules(self):
		rules =  "-F\\n"
		rules += "-t nat -F\\n"
		# if wireless tethering is enabled, but tor_router is not, we shall accept forwarding
		if __addon__.getSetting('tor_router') != "true" and self.IsTethering():
			rules += "-A FORWARD -j ACCEPT\\n"
			rules += "-t nat -A POSTROUTING -j MASQUERADE\\n"
		src = ""
		if __addon__.getSetting('anyaddress') != "true":
			src = " -s " + __addon__.getSetting('trustednet')
		rules += "-A INPUT -i lo -j ACCEPT\\n"
		rules += "-A INPUT -p icmp --icmp-type any -j ACCEPT\\n"
		rules += "-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\\n"
		if __addon__.getSetting('enable_i2p') == "true":
			router_port = GetPortValue(__addon__.getSetting('mountpoint') + "/i2p/router.config", "i2np.udp.port", "9000:31000")				
			rules += "-A INPUT -m udp -p udp --dport " + router_port + " -j ACCEPT\\n"
			rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + router_port + " -j ACCEPT\\n"
			# NB: must read ports from configuration!
			for prt in [ 4444, 4445, 6668, 7654, 7657, 7659, 7660, 8998 ]:
				rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + str(prt) + src  + " -j ACCEPT\\n"

		if __addon__.getSetting('enable_tor') == "true":
			rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + __addon__.getSetting('tor_orport') + " -j ACCEPT\\n"
			rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + __addon__.getSetting('tor_socksport') + " " + src + " -j ACCEPT\\n"
			if __addon__.getSetting('tor_obfsproxy') == "true":
				if __addon__.getSetting('tor_obfs2on') == "true":
					rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + __addon__.getSetting('tor_obfs2port') + " -j ACCEPT\\n"
				if __addon__.getSetting('tor_obfs3on') == "true":
					rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + __addon__.getSetting('tor_obfs3port') + " -j ACCEPT\\n"
				if __addon__.getSetting('tor_obfs4on') == "true" and __addon__.getSetting('tor_obfs4proxy') == "true":
					rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport " + __addon__.getSetting('tor_obfs4port') + " -j ACCEPT\\n"
			if __addon__.getSetting('tor_router') == "true":
				non_tor = [ "10.0.0.0/8", "192.168.0.0/16", "172.16.0.0./12" ]
				rules += "-A OUTPUT -m conntrack --ctstate INVALID -j DROP\\n"
				rules += "-A OUTPUT -m state --state INVALID -j DROP\\n"
				rules += "-A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,FIN ACK,FIN -j DROP\\n"
				rules += "-A OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,RST ACK,RST -j DROP\\n"
				rules += "-A OUTPUT -t nat -o lo -j RETURN\\n"
				rules += "-A OUTPUT -t nat -m owner --gid-owner 990 -j RETURN\\n"
				rules += "-A OUTPUT -t nat -p udp --dport 53 -j REDIRECT --to-ports 53\\n"
				for clearnet in non_tor:
					rules += "-A OUTPUT -t nat -d " + clearnet + " -j RETURN\\n"
					rules += "-A PREROUTING -t nat -i " + __addon__.getSetting('tor_routefrom') + " -d " + clearnet + " -j RETURN\\n"
				rules += "-A OUTPUT -t nat -p tcp --syn -j REDIRECT --to-ports 9040\\n"
				rules += "-A PREROUTING -t nat -i " + __addon__.getSetting('tor_routefrom') + " -p udp --dport 53 -j REDIRECT --to-ports 53\\n"
				rules += "-A PREROUTING -t nat -i " + __addon__.getSetting('tor_routefrom') + " -p tcp --syn -j REDIRECT --to-ports 9040\\n"
				rules += "-A INPUT -m udp -p udp --dport 53 -i " + __addon__.getSetting('tor_routefrom') + " -j ACCEPT\\n"
				rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport 9040 -i " + __addon__.getSetting('tor_routefrom') + " -j ACCEPT\\n"
				rules += "-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\\n"
				rules += "-A OUTPUT -d 127.0.0.0/8 -j ACCEPT\\n"
				for clearnet in non_tor:
					rules += "-A OUTPUT -d " + clearnet + " -j ACCEPT\\n"
				rules += "-A OUTPUT -m owner --gid-owner 990 -j ACCEPT\\n"
				rules += "-A OUTPUT -j REJECT\\n"

		if __addon__.getSetting('enable_privoxy') == "true":
			rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport 8118 " + src + " -j ACCEPT\\n"

		if __addon__.getSetting('enable_web') == "true":
			rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 " + src + " -j ACCEPT\\n"

		if __addon__.getSetting('enable_ssh') == "true":
			rules += "-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 " + src + " -j ACCEPT\\n"

		if __addon__.getSetting('enable_vpn') == "true":
			rules += "-A INPUT -m udp -p udp --dport 1194 " + src + " -j ACCEPT\\n"

		# Tethering (must be enabled before activating AntiPrism!)
		rules += "-A INPUT -i tether -p udp --dport 67:68 --sport 67:68 -j ACCEPT\\n"
		
		# UPnP
		rules += "-A INPUT -m state --state NEW -m tcp -p tcp " + src + " --dport 5000 -j ACCEPT\\n"
		rules += "-A INPUT -m udp -p udp " + src + " --dport 1900 -j ACCEPT\\n"

		# Only allow the local Tor user group's processes to access the hidden website ports
		rules += "-A OUTPUT -p tcp -d 127.0.0.0/8 --dport 7658 -m owner ! --gid-owner 990 -j REJECT\\n"
		rules += "-A OUTPUT -p tcp -d 127.0.0.0/8 --dport 8080 -m owner ! --gid-owner 990 -j REJECT\\n"

		rules += "-A INPUT -j DROP\\n"

		#try:
		#	with open("/storage/extra.rulez", "rt") as f:
		#		for line in f:
		#			rules += (line + "\\n")
		#	f.close()
		#except:
		#	pass
		return rules

	def SHOW(self, ctrl):
		for i in ctrl:
			self.getControl(i).setVisible(True)

	def HIDE(self, ctrl):
		for i in ctrl:
			self.getControl(i).setVisible(False)	

	
