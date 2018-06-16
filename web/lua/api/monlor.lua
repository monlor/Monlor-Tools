module("luci.controller.api.monlor", package.seeall)

function index()
	local page   = node("api","monlor")
	page.target  = firstchild()
	page.title   = ("")
	page.order   = 100
	page.sysauth = "admin"
	page.sysauth_authenticator = "jsonauth"
	page.index = true

	entry({"api", "monlor", "ss_get"}, call("ssGet"), (""), 101)
        entry({"api", "monlor", "ss_start"}, call("ssStart"), (""), 102)
        entry({"api", "monlor", "ss_stop"}, call("ssStop"), (""), 103)		
        entry({"api", "monlor", "koolproxy_get"}, call("koolproxyGet"), (""), 201)
        entry({"api", "monlor", "koolproxy_start"}, call("koolproxyStart"), (""), 202)
        entry({"api", "monlor", "koolproxy_stop"}, call("koolproxyStop"), (""), 203)
        entry({"api", "monlor", "frp_get"}, call("frpGet"), (""), 301)
        entry({"api", "monlor", "frp_start"}, call("frpStart"), (""), 302)
        entry({"api", "monlor", "frp_stop"}, call("frpStop"), (""), 303)
        entry({"api", "monlor", "tinyproxy_get"}, call("tinyproxyGet"), (""), 401)
        entry({"api", "monlor", "tinyproxy_start"}, call("tinyproxyStart"), (""), 402)
        entry({"api", "monlor", "tinyproxy_stop"}, call("tinyproxyStop"), (""), 403)
	entry({"api", "monlor", "kms_get"}, call("kmsGet"), (""), 501)
	entry({"api", "monlor", "kms_start"}, call("kmsStart"), (""), 502)
	entry({"api", "monlor", "kms_stop"}, call("kmsStop"), (""), 503)
	entry({"api", "monlor", "aria2_get"}, call("aria2Get"), (""), 601)
        entry({"api", "monlor", "aria2_start"}, call("aria2Start"), (""), 602)
        entry({"api", "monlor", "aria2_stop"}, call("aria2Stop"), (""), 603)	
        entry({"api", "monlor", "webshell_get"}, call("webshellGet"), (""), 701)
        entry({"api", "monlor", "webshell_start"}, call("webshellStart"), (""), 702)
        entry({"api", "monlor", "webshell_stop"}, call("webshellStop"), (""), 703)
        entry({"api", "monlor", "nginx_get"}, call("nginxGet"), (""), 801)
        entry({"api", "monlor", "nginx_start"}, call("nginxStart"), (""), 802)
        entry({"api", "monlor", "nginx_stop"}, call("nginxStop"), (""), 803)
        entry({"api", "monlor", "fastdick_get"}, call("fastdickGet"), (""), 901)
        entry({"api", "monlor", "fastdick_start"}, call("fastdickStart"), (""), 902)
        entry({"api", "monlor", "fastdick_stop"}, call("fastdickStop"), (""), 903)
		
end

local LuciHttp = require("luci.http")
local LuciUtil = require("luci.util")
local json = require("cjson")
local uci = require("luci.model.uci").cursor()
local XQConfigs = require("xiaoqiang.common.XQConfigs")
local XQSysUtil = require("xiaoqiang.util.XQSysUtil")
local XQErrorUtil = require("xiaoqiang.util.XQErrorUtil")
local monlorpath = uci:get("monlor", "tools", "path")
-- ss
function ssGet()   
        local appname = "shadowsocks"                                                                                                                   
        local result = {}    
        -- local sslist = {}                                                   
        -- status = tonumber(LuciUtil.exec("ps | grep ss-redir | grep -v grep | wc -l"))
        LuciUtil.exec("rm -rf /tmp/pstmp.txt")
        status = tonumber(LuciUtil.exec(monlorpath.."/apps/"..appname.."/script/"..appname..".sh status | tail -1"))
        result["enable"] = uci:get("monlor", appname, "enable")    
        result["ssgena"] = uci:get("monlor", appname, "ssgena")               
        result["status"] = status                                           
        result["code"] = 0 
	result["ssid"] = uci:get("monlor", appname, "id")
	result["ssgid"] = uci:get("monlor", appname, "ssgid") 
        result["ssmode"] = uci:get("monlor", appname, "ss_mode") 
        result["ssgmode"] = uci:get("monlor", appname, "ssg_mode")
        -- 获得ss节点
        local conf=LuciUtil.exec("cat "..monlorpath.."/apps/"..appname.."/config/ssserver.conf | awk -F ',' '{print $1}'")
        local sslist=string.split(conf,'\n') 
        -- for i,v in pairs(ssnamelist) do 
        --         if ssnamelist[i] ~= '' then
        --                 sslist[i] = ssnamelist[i]
        --         end
        -- end          
        result["sslist"] = sslist                                     
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function ssStart()                                                     
        
        local appname = "shadowsocks"
        local enable = LuciHttp.formvalue("enable") 
        local ssid = LuciHttp.formvalue("ssid")
        local ssmode = LuciHttp.formvalue("ssmode")
        local ssgena = LuciHttp.formvalue("ssgena")
        local ssgid = LuciHttp.formvalue("ssgid")
        local ssgmode = LuciHttp.formvalue("ssgmode")
        local result = {}        
        LuciUtil.exec("uci set monlor."..appname..".enable="..enable) 
        LuciUtil.exec("uci set monlor."..appname..".id="..ssid)
        LuciUtil.exec("uci set monlor."..appname..".ss_mode="..ssmode)
        LuciUtil.exec("uci set monlor."..appname..".ssgena="..ssgena)
        LuciUtil.exec("uci set monlor."..appname..".ssgid="..ssgid)
        LuciUtil.exec("uci set monlor."..appname..".ssg_mode="..ssgmode)
        LuciUtil.exec("uci commit monlor") 
        LuciUtil.exec(monlorpath.."/apps/"..appname.."/script/"..appname..".sh restart")                                    
        result["code"] = 0
        result["ssid"] = ssid
        LuciHttp.write_json(result)                     
                                                                         
end                                                                            
                                                                      
function ssStop()                                                        
                
        local appname = "shadowsocks"
        local enable = LuciHttp.formvalue("enable") 
        local ssid = LuciHttp.formvalue("ssid")
        local ssmode = LuciHttp.formvalue("ssmode")
        local ssgena = LuciHttp.formvalue("ssgena")
        local ssgid = LuciHttp.formvalue("ssgid")
        local ssgmode = LuciHttp.formvalue("ssgmode")
        local result = {}        
        LuciUtil.exec("uci set monlor."..appname..".enable="..enable) 
        LuciUtil.exec("uci set monlor."..appname..".id="..ssid)
        LuciUtil.exec("uci set monlor."..appname..".ss_mode="..ssmode)
        LuciUtil.exec("uci set monlor."..appname..".ssgena="..ssgena)
        LuciUtil.exec("uci set monlor."..appname..".ssgid="..ssgid)
        LuciUtil.exec("uci set monlor."..appname..".ssg_mode="..ssgmode)
        LuciUtil.exec("uci commit monlor")                                                        
        LuciUtil.exec(monlorpath.."/apps/"..appname.."/script/"..appname..".sh stop")                                    
        result["code"] = 0
        LuciHttp.write_json(result)                       
                                                                                
end 

-- koolproxy
function koolproxyGet()                                                               
        
        local appname = "koolproxy"                                                        
        local result = {}                                                       
        LuciUtil.exec("rm -rf /tmp/pstmp.txt")
        status = tonumber(LuciUtil.exec(monlorpath.."/apps/"..appname.."/script/"..appname..".sh status | tail -1"))
        result["enable"] = uci:get("monlor", appname, "enable") 
        result["status"] = status                                               
        result["code"] = 0 
	result["mode"] = uci:get("monlor", appname, "mode")
        result["autorule"] = uci:get("monlor", appname, "autorule")                                                  
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function koolproxyStart()                                                     
                  
        local appname = "koolproxy"
        local result = {}
        local enable = LuciHttp.formvalue("enable")                                                     
        local mode = LuciHttp.formvalue("mode")
        local autorule = LuciHttp.formvalue("autorule")
        LuciUtil.exec("uci set monlor."..appname..".enable="..enable)
        LuciUtil.exec("uci set monlor."..appname..".mode="..mode)
        LuciUtil.exec("uci set monlor."..appname..".autorule="..autorule)
        LuciUtil.exec("uci commit monlor")                                                        
        LuciUtil.exec(monlorpath.."/apps/"..appname.."/script/"..appname..".sh restart")                                    
        result["code"] = 0
        LuciHttp.write_json(result)                    
                                                                                
end                                                                            
                                                                      
function koolproxyStop()                                                        
                                                                        
        local appname = "koolproxy"
        local result = {}
        local enable = LuciHttp.formvalue("enable")                                                     
        local mode = LuciHttp.formvalue("mode")
        local autorule = LuciHttp.formvalue("autorule")
        LuciUtil.exec("uci set monlor."..appname..".enable="..enable)
        LuciUtil.exec("uci set monlor."..appname..".mode="..mode)
        LuciUtil.exec("uci set monlor."..appname..".autorule="..autorule)
        LuciUtil.exec("uci commit monlor")                                                        
        LuciUtil.exec(monlorpath.."/apps/"..appname.."/script/"..appname..".sh stop")                                    
        result["code"] = 0
        LuciHttp.write_json(result)                      
                                                                                
end 

-- frp
function frpGet()                                                               
                                                                                
        local result = {}                                                       
        status = tonumber(LuciUtil.exec("ps | grep frpc | grep -v grep | wc -l"))
        result["enable"] = uci:get("monlor", "frpc", "enable")                   
        result["status"] = status                                               
        result["code"] = 0                                                      
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function frpStart()                                                     
                                                                      
        return os.execute("/etc/monlor/script/frpc enable")                      
                                                                                
end                                                                            
                                                                      
function frpStop()                                                        
                                                                        
        return os.execute("/etc/monlor/script/frpc disable")                     
                                                                                
end 

-- tinyproxy
function tinyproxyGet()                                                               
                                                                                
        local result = {}                                                       
        status = tonumber(LuciUtil.exec("ps | grep tinyproxy | grep -v grep | wc -l"))
        result["enable"] = uci:get("monlor", "tinyproxy", "enable")                   
        result["status"] = status                                               
        result["code"] = 0                                                      
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function tinyproxyStart()                                                     
                                                                      
        return os.execute("/etc/monlor/script/tinyproxy enable")                      
                                                                                
end                                                                            
                                                                      
function tinyproxyStop()                                                        
                                                                        
        return os.execute("/etc/monlor/script/tinyproxy disable")                     
                                                                                
end 

-- kms
function kmsGet()
	
	local result = {}
	status = tonumber(LuciUtil.exec("ps | grep kms | grep -v grep | wc -l"))
	result["enable"] = uci:get("monlor", "kms", "enable")
	result["status"] = status
	result["code"] = 0	
	LuciHttp.write_json(result)
	return result
end

function kmsStart()

	return os.execute("/etc/monlor/script/kms enable")
	
end

function kmsStop()
	
	return os.execute("/etc/monlor/script/kms disable")
	
end

-- aria2
function aria2Get()                                                               
                                                                                
        local result = {}                                                       
        status = tonumber(LuciUtil.exec("ps | grep aria2 | grep -v grep | wc -l"))
        result["enable"] = uci:get("monlor", "aria2", "enable")                   
        result["status"] = status                                               
        result["code"] = 0                                                      
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function aria2Start()                                                     
                                                                      
        return os.execute("/etc/monlor/script/aria2 enable")                      
                                                                                
end                                                                            
                                                                      
function aria2Stop()                                                        
                                                                        
        return os.execute("/etc/monlor/script/aria2 disable")                     
                                                                                
end 

-- webshell
function webshellGet()                                                               
                                                                                
        local result = {}                                                       
        status = tonumber(LuciUtil.exec("ps | grep webshell | grep -v grep | wc -l"))
        result["enable"] = uci:get("monlor", "webshell", "enable")                   
        result["status"] = status                                               
        result["code"] = 0                                                      
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function webshellStart()                                                     
                                                                      
        return os.execute("/etc/monlor/script/webshell enable")                      
                                                                                
end                                                                            
                                                                      
function webshellStop()                                                        
                                                                        
        return os.execute("/etc/monlor/script/webshell disable")                     
                                                                                
end 

-- nginx
function nginxGet()                                                               
                                                                                
        local result = {}                                                       
        status = tonumber(LuciUtil.exec("ps | grep mnginx | grep -v grep | wc -l"))
        result["enable"] = uci:get("monlor", "nginx", "enable")                   
        result["status"] = status                                               
        result["code"] = 0                                                      
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function nginxStart()                                                     
                                                                      
        return os.execute("/etc/monlor/script/nginx enable")                      
                                                                                
end                                                                            
                                                                      
function nginxStop()                                                        
                                                                        
        return os.execute("/etc/monlor/script/nginx disable")                     
                                                                                
end 

-- fastdick
function fastdickGet()                                                               
                                                                                
        local result = {}                                                       
        status = tonumber(LuciUtil.exec("ps | grep fastdick | grep -v grep | wc -l"))
        result["enable"] = uci:get("monlor", "fastdick", "enable")                   
        result["status"] = status                                               
        result["code"] = 0                                                      
        LuciHttp.write_json(result)                                             
        return result                                                           
end                                                          
                                                                    
function fastdickStart()                                                     
                                                                      
        return os.execute("/etc/monlor/script/fastdick enable")                      
                                                                                
end                                                                            
                                                                      
function fastdickStop()                                                        
                                                                        
        return os.execute("/etc/monlor/script/fastdick disable")                     
                                                                                
end 