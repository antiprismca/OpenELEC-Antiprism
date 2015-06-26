# -*- coding: utf-8 -*-
#########################################################################################
# Copyright (c) 2014, AntiPrism.ca
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

import sys, os, logging, subprocess, urllib, httplib, glob, shutil, re, tempfile
import xbmcaddon, xbmcplugin, xbmcgui
from urlparse import parse_qs, urlparse
if sys.version_info < (2, 7):
    import simplejson
else:
    import json as simplejson

addon= xbmcaddon.Addon(id='plugin.program.i2p');

__scriptname__ = "I2P XBMC Frontend"
__author__ = "AntiPrism.ca"
__version__ = "1.0.12"
__home__ = addon.getAddonInfo("path");
__icon__ = os.path.join(__home__, "icon.png");

T = addon.getLocalizedString

I2P_TORRENTS     = 0
I2P_ADDRESS_BOOK = 1
I2P_SECURE_MAIL  = 2
I2P_UNDEFINED    = 99

def clearDirFiles(filepath):
	if not os.path.exists(filepath): return
	for f in os.listdir(filepath):
		f = os.path.join(filepath, f)
		if os.path.isfile(f): os.remove(f)

def touch(fname, times=None):
	with open(fname, 'a'):
		os.utime(fname, times)

def get_params():
	return parse_qs(urlparse(sys.argv[2]).query)

def init_logging(dir):
	logging.basicConfig(level=logging.DEBUG, filename=dir+"/i2p-plugin.log",
	                    filemode="w", format="%(asctime)s %(levelname)-5s %(name)-10s %(threadName)-10s %(message)s")

def address_book(command):
	cmd = os.path.join(addon.getAddonInfo("path"), "bin", "addressbook.sh")
	return subprocess.Popen(cmd + " " + command,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)

def LI(prompt, icon = __icon__, ctx_menu = []):
	li = xbmcgui.ListItem(prompt, thumbnailImage=icon)
	li.addContextMenuItems(ctx_menu, replaceItems=True)
	return li

def addDirItem(category, li, params = {}, folder=True):
	params.update( { "index" : str(category) } )
	params.update( { "homepath" : __homepath__ } )
	xbmcplugin.addDirectoryItem(int(sys.argv[1]), url=sys.argv[0] + "?" + urllib.urlencode(params), listitem=li, isFolder=folder)

def getNonce():
	conn = httplib.HTTPConnection("127.0.0.1", 7657)
	conn.request("GET", "/i2psnark/")
	r = conn.getresponse()
	data = re.sub('[\n]', '', r.read())
	nonce = re.findall(r'name="nonce" value="([^"]+?)"', data)[0]
	conn.close()
	del conn
	return nonce

params = get_params();
index = None;

__deaddropurl__ = addon.getSetting("deaddropurl")
if __deaddropurl__ is None or __deaddropurl__ == "":
	__deaddropurl__ = "http://www.antiprism.ca/deaddrop/"

try:
	index = int(params["index"][0])
except:
	pass;

try:
	__homepath__ = params["homepath"][0]
except:
	xbmcgui.Dialog().ok("", " ", T(32002))
	__homepath__ = None

if addon.getSetting('logging') == 'true':
	init_logging(__homepath__)
dialog = xbmcgui.Dialog()

if __homepath__ is None:
	xbmc.executebuiltin("XBMC.Container.Update(path,replace)")
	xbmc.executebuiltin("XBMC.ActivateWindow(Home)")

elif index is None:
	addDirItem(I2P_TORRENTS, LI(T(32003)));
	addDirItem(I2P_ADDRESS_BOOK, LI(T(32004)));

elif index == I2P_TORRENTS:
	filepath = os.path.join(__homepath__, "i2p", "i2psnark")
	if not os.path.exists(filepath):
		dialog.ok(T(32010), " ", filepath)
	else:	
		op = None
		try:
			op = params["op"][0]
			if op == "open":
				xbmc.executebuiltin("XBMC.ActivateWindow(filemanager, " + filepath + ")")

			elif op == "add":
				file = dialog.browse(1, T(32011), "files", ".torrent")
				if file is not None and file != "":
					dest = os.path.join(filepath, os.path.basename(file))
					if not os.path.exists(dest) or dialog.yesno(T(32012), " ", T(32013)):
						try:
							shutil.copyfile(file, filepath)
							xbmc.executebuiltin("Container.Refresh")
						except:	
							dialog.ok(T(32014), " ", T(32015))

			elif op == "start_all" or op == "stop_all":
				nonce = getNonce()
				if op == "start_all":
					act = "Start"
				else:
					act = "Stop"
				p = subprocess.Popen("http_proxy=\"\" curl --data-ascii \"action_" + act + "All.x=1&action_StartAll.y=1&nonce=" + nonce + "\" http://127.0.0.1:7657/i2psnark/_post",stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
				output, errors = p.communicate()
				if p.returncode != 0:
					dialog.ok(T(32014), str(errors))

			elif op == "search":
				searching = str(dialog.input(T(32028), None))
				if searching is not None:
					categoryidx = dialog.select(T(32029), [ "All", "Movies", "Music", "TV", "Games", "Apps", "Misc.", "Pictures", "Anime", "Comics", "Books", "Audio Books", "Music Vid.", "PrOn", "Documentary", "Leaked Documents", "Conspiracy" ])
					category = [ -1, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 17, 13, 14, 15, 16, 18 ][categoryidx] 
					orderby = dialog.select(T(32030), [ "Default", "Time added", "Downloads", "Hits", "Comments", "Swarmsize", "Rating" ])
					if orderby == 0:
						orderby = -1
					showidx = dialog.select(T(32031), [ "Active torrents", "Active last 24h", "Active last 48h", "Active last week", "Active last 2 weeks", "W/o seeders", "Abandoned torrents", "All torrents" ])
					show = [ 0, 1, 2, 7, 14, -3, -2, -1 ][showidx]
					language = dialog.select(T(32032), [ "Any language", "English", "German", "French", "Spanish", "Portugese", "Dutch", "Russian", "Swedish", "Italian", "Chinese", "Finnish", "Japanese", "Turkish" ])
					if language == 0:
						language = -1
					start = -1
					new_start = 0
					results = []
					cookie = ""
					oldurl = ""
					agent = "Mozilla/5.0 (X11; Linux i686; rv:24.0) Gecko/20140723 Firefox/24.0 Iceweasel/24.7.0"
					while True:
						if start != new_start:
							start = new_start
							results = []
							progress = xbmcgui.DialogProgressBG()
							progress.create(T(32069), T(32071))
							more = "/?"
							if start > 0: more = "/index.php?view=Main&start=" + str(start) + "&limit=20&"
							url = "http://tracker2.postman.i2p" + more + "search="+urllib.quote(searching)+"&category="+str(category)+"&orderby="+str(orderby)+"&lastactive="+str(show)+"&lang="+str(language)
							referer = ""
							if oldurl != "":
								referer = " -e \"" + oldurl + "\""
							p = subprocess.Popen("http_proxy=127.0.0.1:4444 curl -A \"" + agent + "\" -i " + referer + cookie + " \"" + url + "\"",stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
							oldurl = url
							output, errors = p.communicate()                                                                                                                                           
							if p.returncode != 0:
								dialog.ok(T(32014), str(errors))
							else:
								progress.update(100)
								data = re.sub('[\n]', '', str(output))
								setcookie = re.findall(r'Set-Cookie: ([^;].+?);', data)
								if len(setcookie) > 0:
									cookie = " -b \"" + setcookie[0] + "\""
								pattern1 = r'<ul class="topiclist topics">(.+?)</ul>' 
								torrent_blocks = re.findall(pattern1, data) 
								for torrent in torrent_blocks:
									try:
										info = re.findall(r'<dd class="views">([^<]+?)</dd>', torrent)
										cat = info[0]
										title = re.findall(r'view=TorrentDetail&id=([^"]+?)" title="([^"]+?)">', torrent)[0][1]
										language = ""
										lang = re.findall(r'title="Main language: ([^"]+?)"', torrent)
										if len(lang) > 0:
											language = lang[0]
										comment = ""
										comm = re.findall(r'</a><br /><span class="small">([^<]+?)<br><b>Rating:', torrent)
										if len(comm) > 0:
											comment = comm[0]
										rating = len(re.findall(r'"/images/full.png"', torrent)) * 20 + len(re.findall(r'"/images/half.png"', torrent)) * 10 
										maggot = re.findall(r'<a href="maggot://([^"]+?)"', torrent)[0]
										size = info[2]
										results = results + [ { "category" : cat, "title" : title, "maggot" : maggot, "size" : size, "language" : language, "rating" : str(rating)+"%", "comment" : comment } ]
									except:
										pass
							progress.close()
							del progress
						len_res = len(results)
						if len_res == 0:
							dialog.ok(T(32024), " ", T(32037))
							break
						else:
							down_idx = dialog.select(T(32033), [ res["category"] + ": " + res["title"] + " (" + res["size"] + ")" for res in results ] + [ T(32034), T(32035), T(32036) ])
							if down_idx == len_res + 2: 
								break  # Done
							elif down_idx == len_res + 1:
								new_start = start + len_res
							elif down_idx == len_res:
								new_start = start - len_res
								if new_start < 0: new_start = 0
							else:
								if dialog.yesno(T(32038), results[down_idx]["title"], results[down_idx]["size"]+"   "+results[down_idx]["language"]+"   rating:"+results[down_idx]["rating"], results[down_idx]["comment"]):
									nonce = getNonce()
									p = subprocess.Popen("http_proxy=\"\" curl --data-ascii \"nofilter_newURL=maggot://" + results[down_idx]["maggot"] + "&foo=Add%20torrent&action=Add&nonce=" + nonce + "\" http://127.0.0.1:7657/i2psnark/_post",stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
									output, errors = p.communicate() 
									if p.returncode != 0: 
										dialog.ok(T(32014), str(errors))

					xbmc.executebuiltin("Container.Refresh")

			elif op == "info":
				conn = httplib.HTTPConnection("127.0.0.1", 7657)
				conn.request("GET", "/i2psnark/.ajax/xhr1.html")
				r = conn.getresponse()
				data = re.sub('[\n]', '', r.read())
				pattern1 = r'<tr class="snarkTorrent(.+?)</tr>'
				torrent_blocks = re.findall(pattern1, data)
				for torrent in torrent_blocks:
					s = os.path.splitext(os.path.basename(params["filename"][0]))
					if len(s) == 0: continue
					srch = s[0]
					if torrent.find(srch.replace("&", "&amp;")) > -1 or torrent.find(urllib.quote(srch)) > -1:
						try:
							pattern2 = r'<td class="snarkTorrentStatus">([^<]+?)</td>'
							status_block = re.sub("&.*?;", "", str(re.findall(pattern2, torrent)[0]).replace("&nbsp;", " "))
						except:
							status_block = T(32023)
						try:
							pattern3 = r'<td align="right" class="snarkTorrentDownloaded">([^<]+?)</td>'
							down_block = re.sub("&.*?;", "", str(re.findall(pattern3, torrent)[0]).replace("&nbsp;", " "))
						except:
							down_block = "-"
						try:
							pattern4 = r'<td align="right" class="snarkTorrentUploaded">([^<]+?)</td>'
							up_block = re.sub("&.*?;", "", str(re.findall(pattern4, torrent)[0]).replace("&nbsp;", " "))
						except:
							up_block = "-"
						dialog.ok(T(32020), T(32024)+status_block.decode("utf-8"), T(32025)+str(down_block), T(32026)+str(up_block))
						break
				conn.close()

			elif op == "delete":
				if dialog.yesno(T(32016), params["filename"][0]) == True:
					try:
						os.unlink(params["filename"][0])
						xbmc.executebuiltin("Container.Refresh")
					except:
						dialog.ok(T(32014), " ", T(32022))	
		except:
			pass

		addDirItem(I2P_TORRENTS, LI(T(32017)), { "op" : "open" }, False);
		addDirItem(I2P_TORRENTS, LI(T(32018)), { "op" : "add" }, False);
		addDirItem(I2P_TORRENTS, LI(T(32027)), { "op" : "search" }, False);

		listing = glob.glob(os.path.join(filepath, "*.torrent"))
		if len(listing):
			addDirItem(I2P_UNDEFINED, LI(T(32019)), {}, False);
			for filename in listing:
				command = "XBMC.RunPlugin("+sys.argv[0]+"?index=0&homepath="+__homepath__+"&filename="+urllib.quote(filename)
				li = LI("  " + os.path.splitext(os.path.basename(filename))[0], 
				        __icon__,
				        [ (T(32020), command+"&op=info)"),
				          (T(32021), command+"&op=delete)") ] )
				addDirItem(I2P_UNDEFINED, li, {}, False);
			addDirItem(I2P_TORRENTS, LI(T(32072)), { "op" : "start_all" }, False);
			addDirItem(I2P_TORRENTS, LI(T(32073)), { "op" : "stop_all" }, False);
	
elif index == I2P_ADDRESS_BOOK:
	id = None
	op = None
	select_all = False
	unselect_all = False
	selected = []
	try:
		sel = params["selected"][0]
		if sel is not None:
			selected = simplejson.loads(sel)
	except:
		pass

	try:
		id = params["id"][0]
	except:
		pass

	try:
		op = params["op"][0]
	except:
		pass

	if id is not None:
		# toggle the "selected" status
		if id in selected:
			selected.remove( id )
		else:
			selected.append( id )

	sel = simplejson.dumps(selected)

	i2pbotepass = None
	try:
		i2pbotepass = params["i2pbotepass"][0][1:]
	except:
		i2pbotepass = dialog.input(T(32052), "", type=xbmcgui.INPUT_ALPHANUM, option=xbmcgui.ALPHANUM_HIDE_INPUT)

	if op == "import":
		method = dialog.select(T(32065), [ T(32066), T(32067), T(32060) ])
		if method != 2:
			file = None
			if method == 0:
				file = dialog.browse(1, T(32050), "files")
			else:
				f = tempfile.NamedTemporaryFile(delete=True)
				file = f.name
				f.close()
				drop_id = dialog.input(T(32068), "")
				if drop_id is not None and drop_id != "":
					p = subprocess.Popen("curl -s -A \"AntiPrism DeadDropper\" " + __deaddropurl__ + drop_id + " 2>/dev/null > \"" + file + "\"",stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
					output, errors = p.communicate()
					if p.returncode != 0:
						try:
							f = open(file, "r")
							dialog.ok(T(32014), f.read())
							f.close()
							os.unlink(file)
							file = None
						except:
							pass

			if file is not None and file != "":
				p = address_book("import \"" + __homepath__ + "\" \"" + file + "\"" )
				password = dialog.input(T(32051), "", type=xbmcgui.INPUT_ALPHANUM, option=xbmcgui.ALPHANUM_HIDE_INPUT)
				output, errors = p.communicate(input = simplejson.dumps( { "i2pbotePasswd" : i2pbotepass, "gnupgPasswd" : password } ))
				if p.returncode != 0:
					dialog.ok(T(32014), str(errors))
				selected = []
				sel = simplejson.dumps(selected)
			if method == 1:
				try:
					os.unlink(file)
				except:
					pass

	elif op == "select_all":
		select_all = True

	elif op == "unselect_all":
		unselect_all = True

	elif op == "export" and len(selected) > 0:
		p = address_book("list \"" + __homepath__ + "\"")
		output, errors = p.communicate(input = simplejson.dumps( { "i2pbotePasswd" : i2pbotepass } ))
		if p.returncode == 0:
			json_response = simplejson.loads(output)
			if len(json_response["gnupg"]) > 0:
				keys_selection = [ "  " + key["name"] for key in json_response["gnupg"]]
				while True:
					pos = dialog.select(T(32053), keys_selection + [ T(32059), T(32060) ])
					if pos >= len(json_response["gnupg"]):
						break
					if keys_selection[pos][0] == "+":
						keys_selection[pos] = "  " + json_response["gnupg"][pos]["name"]
					else:
						keys_selection[pos] = "+ " + json_response["gnupg"][pos]["name"]
					
				if pos == len(json_response["gnupg"]):
					keys = []
					for key in keys_selection:
						if key[0] == "+":
							keys = keys + [ json_response["gnupg"][keys_selection.index(key)]["id"] ]

					if len(keys) > 0:
						method = dialog.select(T(32061), [ T(32062), T(32063), T(32060) ])
						if method != 2:
							file = None
							if method == 0:
								file = dialog.input(T(32049), None)
							else:
								f = tempfile.NamedTemporaryFile(delete=True)
								file = f.name
								f.close()
							if file is not None and file != "":
								password = dialog.input(T(32054), "", type=xbmcgui.INPUT_ALPHANUM, option=xbmcgui.ALPHANUM_HIDE_INPUT)
								progress = xbmcgui.DialogProgressBG()
								progress.create(T(32070), T(32071))
								p = address_book("export \"" + __homepath__ + "\" \"" + file + "\"")
								output, errors = p.communicate(input = simplejson.dumps( { "i2pbotePasswd": i2pbotepass, "gnupgPasswd": password, "identities": selected, "recipients": keys } ))
								if p.returncode != 0:
									dialog.ok(T(32014), str(errors))
								else:
									if method == 1:
										# Dead drop submission (implicitely torrified)
										progress.update(50)
										p = subprocess.Popen("curl -s -A \"AntiPrism DeadDropper\" --data-binary @\"" + file + "\" " + __deaddropurl__ + " 2>/dev/null",stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,shell=True)
										output, errors = p.communicate()
										progress.update(100)
										dialog.ok(T(32024), str(output), str(errors))
										os.unlink(file)
									else:
										dialog.ok(T(32024), " ", T(32058))
								progress.close()
								del progress
	progress = xbmcgui.DialogProgressBG()                                                                                                                      
	progress.create(T(32070), T(32071))
	p = address_book("list \"" + __homepath__ + "\"")
	output, errors = p.communicate(input = simplejson.dumps( { "i2pbotePasswd" : i2pbotepass } ))
	progress.close()
	del progress
	if p.returncode == 0:
		json_response = simplejson.loads(output)
		if len(json_response["i2pbote"]) > 0:
			cmd = "select_all"
			if select_all:
				cmd = "unselect_all"
				selected = [ str(contact["id"]) for contact in json_response["i2pbote"] ]
				sel = simplejson.dumps(selected)
			elif unselect_all:
				selected = []
				sel = simplejson.dumps(selected)

			addDirItem(I2P_ADDRESS_BOOK, LI(T(32057)), { "i2pbotepass" : ":"+str(i2pbotepass), "op" : cmd, "selected" : sel }, True);
		for i2pbote in json_response["i2pbote"]:
			if i2pbote["id"] in selected:
				li = LI("+ "+i2pbote["name"])
			else:
				li = LI("  "+i2pbote["name"])
			addDirItem(I2P_ADDRESS_BOOK, li, { "i2pbotepass" : ":"+str(i2pbotepass), "selected" : sel, "id" : i2pbote["id"] });
	else:
		dialog.ok(T(32014), str(errors))

	addDirItem(I2P_ADDRESS_BOOK, LI(T(32055)), { "i2pbotepass" : ":"+str(i2pbotepass), "op" : "import", "selected" : sel }); 
	if len(selected) > 0: 
		addDirItem(I2P_ADDRESS_BOOK, LI(T(32056)), { "i2pbotepass" : ":"+str(i2pbotepass), "op" : "export", "selected" : sel }, False);

elif index == I2P_SECURE_MAIL:
	dialog.ok(T(32005), "TODO")

else:
	pass	

xbmcplugin.endOfDirectory(int(sys.argv[1]),updateListing=True,cacheToDisc=False)
del dialog

