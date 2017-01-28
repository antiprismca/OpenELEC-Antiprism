# -*- coding: utf-8 -*-
#########################################################################################
# Copyright (c) 2014-2016, AntiPrism.ca
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

import xbmc, xbmcaddon, xbmcgui, sys, os
__addon__ = xbmcaddon.Addon(id='script.service.antiprism')
sys.path.append( os.path.join (__addon__.getAddonInfo('path'), 'resources','lib') );
import antiprism

__plugin__ = 'AntiPrism'
__author__ = 'AntiPrism.ca'
__url__ = 'http://www.antiprism.ca/'
__date__ = '01-01-2017'
__version__ = '1.2.25'
THEME = 'Default'

if __name__ == '__main__':
	w = None
	apath = xbmc.translatePath(__addon__.getAddonInfo('path'))
	if len(sys.argv) > 1 and sys.argv[1] == "password":
		w = antiprism.AntiPrismPasswordWindow('script-antiprism-screensaver.xml', apath, THEME)
	else:
		running = False
		try:
			if os.environ["ANTIPRISM_STARTED"] == "yes":
				running = True
		except:
			pass
		if running or __addon__.getSetting('autostart') == "true":
			w = antiprism.AntiPrismWindow('script-antiprism-welcome.xml', apath, THEME)
	os.environ["ANTIPRISM_STARTED"] = "yes"
	if w is not None:
		w.doModal()
		if w.container is not None:
			del w.container
		del w
	sys.modules.clear()
	
