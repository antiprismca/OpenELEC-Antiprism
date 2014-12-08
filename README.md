
# [AntiPrism](http://antiprism.ca)

AntiPrism is a tool for very secure web-browsing and communication. 
It is implemented as a set of extensions to the [OpenELEC](http://www.openelec.tv)-derived media 
center software providing a universal and seamlessly integrated web privacy 
solution for home and small office. 

**Source code**

* https://github.com/antiprismca/OpenELEC-Antiprism

**How to build**

* See how OpenELEC can be [compiled from source](http://wiki.openelec.tv/index.php/Compile_from_source), 
check if your system meets the requirements, install needed compilers and tools.
* Keep in mind following differences:
 * only *i386* and *x86_64* architectures are supported in Antiprism
 * additional software tools are needed: [Ant](http://ant.apache.org/) and 
 [JDK](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html). Only Oracle JDK7 is tested
 but other versions may work as well. Obviously, Ant and JDK can be installed from packages on your Linux.
* Following command will run the 32-bit build
 
        ANT_HOME=/path/to/ant/home \
        JAVA_HOME=/path/to/jdk \
        PROJECT=Generic \
        ARCH=i386 \
        make release 

* Following command will run the 64-bit build
 
        ANT_HOME=/path/to/ant/home \
        JAVA_HOME=/path/to/jdk \
        PROJECT=Generic \
        ARCH=x86_64 \
        make release 
        
**Verification of sources**

The OpenELEC-Antiprism project uses the source code of many other open-source projects that gets downloaded from Internet during
the build process. You should run the following shell script to verify that this source code hasn't been falsified:

        ./verify_md5.sh

**License**

AntiPrism is distributed under a mixed-license model.

* The OpenELEC-based platform is distributed under the GNU GPLv2 license. Some components of
the platform can have other open-source licenses. Please look into source files and the "licenses" folder for details.

* The AntiPrism-related addons (AntiPrism, I2P and GnuPG addons) are distributed under a BSD-style license:

        Copyright (c) 2014, AntiPrism.ca
        All rights reserved.

        Redistribution and use in source and binary forms, with or without modification, are permitted provided 
        that the following conditions are met:
        1. Redistributions of source code must retain the above copyright notice, this list of conditions and the
           following disclaimer.
        2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
           the following disclaimer in the documentation and/or other materials provided with the distribution.
        3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or 
           promote products derived from this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
        WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
        PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
        ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
        TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
        HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
        NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
        POSSIBILITY OF SUCH DAMAGE.

**Questions/Support**

* Check out the [Official Website](http://antiprism.ca)


