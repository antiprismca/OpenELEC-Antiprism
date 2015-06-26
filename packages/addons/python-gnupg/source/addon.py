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

import sys, os, logging
import xbmcaddon, xbmcplugin, xbmcgui
addon= xbmcaddon.Addon(id='plugin.program.gnupg');
sys.path.append( os.path.join (addon.getAddonInfo('path'), 'resources','lib') );
import gnupg

__scriptname__ = "GnuPG XBMC Frontend"
__author__ = "AntiPrism.ca"
__version__ = "1.0.6"
__home__ = addon.getAddonInfo('path');
__icon__ = os.path.join(__home__, "icon.png");

GEN_KEY_FLAG = "/tmp/.gen_key"
GPG_GENERATE_KEY   = 0
GPG_IMPORT_KEY     = 1
GPG_DECRYPT        = 2
GPG_SEARCH_KEY     = 4

T = addon.getLocalizedString

def touch(fname, times=None):
    with open(fname, 'a'):
        os.utime(fname, times)

def get_params():
    param=[]
    paramstring=sys.argv[2]
    if len(paramstring)>=2:
        params=sys.argv[2]
        cleanedparams=params.replace('?','')
        if (params[len(params)-1]=='/'):
            params=params[0:len(params)-2]
        pairsofparams=cleanedparams.split('&')
        param={}
        for i in range(len(pairsofparams)):
            splitparams={}
            splitparams=pairsofparams[i].split('=')
            if (len(splitparams))==2:
                param[splitparams[0]]=splitparams[1]
    return param

def init_logging(dir):
    logging.basicConfig(level=logging.DEBUG, filename=dir+"/gpg.log",
                        filemode="w", format="%(asctime)s %(levelname)-5s %(name)-10s %(threadName)-10s %(message)s")

def get_keyserver():
	keyserver = addon.getSetting('keyserver')
	if keyserver == "":
		if dialog.yesno(T(32054), " ", T(32055)) == True:
			keyserver = "pgp.mit.edu"
	return keyserver

def verify_keys():
	if import_result.count > 0:
		xbmc.executebuiltin("Container.Refresh")
		dialog.ok(T(32026), " ", T(32027))
		for fp in import_result.fingerprints:
			if dialog.yesno(T(32051), T(32008) + ": " + fp, " ", T(32052)) != True:
				gpg.delete_keys([ fp ], True)
				gpg.delete_keys([ fp ])
				xbmc.executebuiltin("Container.Refresh")
	else:
		dialog.ok(T(32028), T(32029))

params = get_params();
index = None;

try:
	index = int(params["index"])
except:
	pass;

try:
	homepath = params["homepath"]
except:
	try:
		homepath = os.environ["HOME"]
	except:
		xbmcgui.Dialog().ok("", " ", T(32002))
		homepath = "/storage"

if addon.getSetting('logging') == 'true':
	init_logging(homepath)
gpg = gnupg.GPG(gnupghome=homepath + "/.gnupg")
dialog = xbmcgui.Dialog()

if index is None:
	addon_handle = int(sys.argv[1])
	xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=0&homepath="+homepath, listitem=xbmcgui.ListItem(T(32003), thumbnailImage=addon.getAddonInfo('path') + "/icon.png"), isFolder=False);
	xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=1&homepath="+homepath, listitem=xbmcgui.ListItem(T(32004), thumbnailImage=addon.getAddonInfo('path') + "/icon.png"), isFolder=False);
	xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=4&homepath="+homepath, listitem=xbmcgui.ListItem(T(32056), thumbnailImage=addon.getAddonInfo('path') + "/icon.png"), isFolder=False);
	pkeys = gpg.list_keys(True)
	if len(pkeys) > 0:
		xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=2&homepath="+homepath, listitem=xbmcgui.ListItem(T(32005), thumbnailImage=addon.getAddonInfo('path') + "/icon.png"), isFolder=False);
	keys = gpg.list_keys()
	if len(keys) > 0 or os.path.isfile(GEN_KEY_FLAG):
		prompt = T(32006) + "  (" + homepath + ")"
		xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=3&homepath="+homepath, listitem=xbmcgui.ListItem(prompt, thumbnailImage=addon.getAddonInfo('path') + "/icon.png"), isFolder=False);
		if os.path.isfile(GEN_KEY_FLAG):
			xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=3&homepath="+homepath, listitem=xbmcgui.ListItem(T(32007), thumbnailImage=addon.getAddonInfo('path') + "/icon.png"), isFolder=False);
		for key in keys:
			li = xbmcgui.ListItem(key["keyid"]+"    "+key["uids"][0], thumbnailImage=addon.getAddonInfo('path') + "/icon.png")
			command = "XBMC.RunPlugin("+sys.argv[0]+"?index=3&homepath="+homepath+"&keyid="+key["keyid"]
			li.addContextMenuItems([ (T(32008), command+"&op=fingerprint&fp="+key["fingerprint"]+")"), 
			                         (T(32009), command+"&op=encrypt"+")"), 
			                         (T(32010), command+"&op=encrypt_sign"+")"), 
			                         (T(32011), command+"&op=export"+")"),
			                         (T(32012), command+"&op=exportp"+")"),
			                         (T(32058), command+"&op=send"+")"),
			                         (T(32013), command+"&op=delete&fp="+key["fingerprint"]+")") ], replaceItems=True)
			xbmcplugin.addDirectoryItem(handle=int(sys.argv[1]), url=sys.argv[0]+"?index=3&keyid="+key["keyid"], listitem=li, isFolder=False);
	xbmcplugin.endOfDirectory(int(sys.argv[1]),updateListing=True,cacheToDisc=False)

elif index == GPG_GENERATE_KEY:
	if os.path.isfile(GEN_KEY_FLAG):
		dialog.ok(T(32014), T(32015))
	else:
		email = comment = password = None
		pkey_t = [ "DSA", "RSA" ]
		pkey_type = dialog.select(T(32016), pkey_t)
		pkey_l = [ "1024", "2048" ]
		pkey_length = dialog.select(T(32017), pkey_l)
		skey_t = [ "ELG-E", "RSA" ]
		skey_type = dialog.select(T(32018), skey_t)
		skey_l = [ "2048", "1024" ]
		skey_length = dialog.select(T(32019), skey_l)
		name = dialog.input(T(32020), None)
		if name is not None and name != "":
			email = dialog.input(T(32021), None)
			if email is not None and email != "":
				comment = dialog.input(T(32022), None)
				if comment is not None:
					password = dialog.input(T(32023), None, type=xbmcgui.INPUT_ALPHANUM, option=xbmcgui.ALPHANUM_HIDE_INPUT)
					if password is not None and password !="":
						input_data = gpg.gen_key_input(key_type=pkey_t[pkey_type], key_length=int(pkey_l[pkey_length]), name_real=name, name_comment=comment, name_email=email, 
						                               subkey_type=skey_t[skey_type], subkey_length=int(skey_l[skey_length]), expire_date=0, passphrase=password)
						dialog.ok(T(32024), T(32015))
						touch(GEN_KEY_FLAG)
						xbmc.executebuiltin("Container.Refresh")
						key = gpg.gen_key(input_data)
						os.unlink(GEN_KEY_FLAG)
						xbmc.executebuiltin("Container.Refresh")
	
elif index == GPG_IMPORT_KEY:
	file = dialog.browse(1, T(32025), "files")
	if file is not None:
		try:
			with open(file, "r") as keyfile:
				key_data = keyfile.read()
				import_result = gpg.import_keys(key_data)
				verify_keys()
		except:
			dialog.ok(T(32028), T(32029))

elif index == GPG_SEARCH_KEY:
		keyserver = get_keyserver()
		if keyserver != "":
			query = dialog.input(T(32057), None)
			if query is not None and query != "":
				result = gpg.search_keys(query, keyserver)			
				if len(result) == 0:
					dialog.ok(T(32026), " ", T(32059))
				else:
					pos = dialog.select(T(32060), [key["keyid"]+"   "+key["uids"][0] for key in result] + [T(32061)])
					try:
						keyid = result[pos]["keyid"]
						import_result = gpg.recv_keys(keyserver, keyid)
						verify_keys()
					except:
						pass 

elif index == GPG_DECRYPT:
		file = dialog.browse(1, T(32030), "files")
		if file is not None:
			try:
				password = dialog.input(T(32031), None, type=xbmcgui.INPUT_ALPHANUM, option=xbmcgui.ALPHANUM_HIDE_INPUT)
				result = None
				if password is not None and password != "":
					if dialog.yesno(T(32032), T(32033)) == True:
						result = gpg.decrypt_file(open(file, "rb"), passphrase=password)
					else:
						filew = dialog.input(T(32034), file)
						if filew is not None:
							result = gpg.decrypt_file(open(file, "rb"), passphrase=password, output=filew)
				if result is not None:
					if result.username is not None:
						trust_report = T(32035) + result.username + T(32036) + result.key_id + T(32037) + result.signature_id
					else:
						trust_report = T(32038)
					dialog.ok(T(32039), trust_report)
			except:
				dialog.ok(T(32040), T(32029))

else:
	try:
		keyid = params["keyid"]
		op = params["op"]
		if op == "fingerprint":
			dialog.ok(T(32008), " ", params["fp"])

		elif op == "encrypt" or op == "encrypt_sign":
			file = dialog.browse(1, T(32041), "files")
			if file is not None:
				sign_fp = None
				password = None
				if op == "encrypt_sign":
					private_keys = gpg.list_keys(True)
					if len(private_keys) == 0:
						dialog.ok(T(32042), " ", T(32043))					
					else:
						pos = dialog.select(T(32044), [key["keyid"]+"    "+key["uids"][0] for key in private_keys])
						try:
							sign_fp = private_keys[pos]["fingerprint"]
							password = dialog.input(T(32031), None, type=xbmcgui.INPUT_ALPHANUM, option=xbmcgui.ALPHANUM_HIDE_INPUT)
						except:
							pass
				try:
					if dialog.yesno(T(32032), T(32033)) == True:
						if sign_fp is not None and password is not None:
							enc = gpg.encrypt_file(open(file, "rb"), [ params["keyid"] ], always_trust=True, sign=sign_fp, passphrase=password)
						else:
							enc = gpg.encrypt_file(open(file, "rb"), [ params["keyid"] ], always_trust=True)
					else:
						filew = dialog.input(T(32034), file)
						if filew is not None:
							if sign_fp is not None and password is not None:
								enc = gpg.encrypt_file(open(file, "rb"), [ params["keyid"] ], always_trust=True, output=filew, sign=sign_fp, passphrase=password)
							else:
								enc = gpg.encrypt_file(open(file, "rb"), [ params["keyid"] ], always_trust=True, output=filew)
					dialog.ok(T(32045), enc.status)
				except:
					dialog.ok(T(32046), " ", T(32029))

		elif op == "export" or op == "exportp":
			try:
				ascii_armored_public_keys = gpg.export_keys([ keyid ])
				ascii_armored_private_keys = ""
				if op == "exportp":
					ascii_armored_private_keys = gpg.export_keys([ keyid ], True)
				filew = dialog.input(T(32034), None)
				if filew is not None and filew != "":
					with open(filew, "w") as exportfile:
						exportfile.write(ascii_armored_public_keys)
						exportfile.write(ascii_armored_private_keys)
						exportfile.close()
					dialog.ok(T(32026), " ", T(32053))
			except:
				dialog.ok(T(32047), T(32029))

		elif op == "send":
			keyserver = get_keyserver()
			if keyserver != "":
				send_result = gpg.send_keys(keyserver, keyid)
				dialog.ok(T(32026), " ", str(send_result.__dict__["stderr"]))

		elif op == "delete":
			if dialog.yesno(T(32048), T(32049) + keyid + T(32050)) == True:
				gpg.delete_keys([ params["fp"] ], True)
				gpg.delete_keys([ params["fp"] ])
				xbmc.executebuiltin("Container.Refresh")				 
	except:
		pass	

del gpg
del dialog


