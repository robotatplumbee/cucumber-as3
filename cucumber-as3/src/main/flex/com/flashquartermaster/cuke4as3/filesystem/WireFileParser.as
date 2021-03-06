/**
 * Copyright (c) 2011 FlashQuartermaster Ltd
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * @author Tom Coxen
 * @version
 **/
package com.flashquartermaster.cuke4as3.filesystem
{
import com.flashquartermaster.cuke4as3.Config;
import com.flashquartermaster.cuke4as3.vo.CucumberServerInfo;

import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;

public class WireFileParser
	{

		public function getServerInfoFromWireFile(srcDir:String, port:uint):CucumberServerInfo
		{
            var serverInfo : CucumberServerInfo

            if(port > 0)
            {
                serverInfo = new CucumberServerInfo();
                serverInfo.port = port;
                return serverInfo;
            }

			const featuresDir:File = new File( srcDir + File.separator + Config.FEATURES_DIR );
            const stepsDir:File = new File( srcDir + File.separator + Config.STEP_DEFINITIONS_DIR );

			//Cucumber reads the steps directory first then the features directory so we shall do the same
            if(stepsDir.exists)
            {
                var wireFile : File = getWireFileFromDirectory( stepsDir.getDirectoryListing() );
            }

			if(wireFile == null && featuresDir.exists)
            {
                wireFile = getWireFileFromDirectory( featuresDir.getDirectoryListing() );
            }

			if(wireFile)
			{
                serverInfo = processWireFile(wireFile);
                serverInfo.port = port > 0 ? port : serverInfo.port;
                return serverInfo;
			}
			else
			{
				throw new Error("No wire file found in \"" + featuresDir.nativePath + "\" or \"" + stepsDir.nativePath + "\"");
			}
		}

		private function getWireFileFromDirectory( directory:Array ):File
		{
			var i:uint = directory.length;
			var name:String;
			var wireFile:File;

			while( --i > -1 )
			{
				var file:File = directory[i] as File;
				name = file.name;
				if( name.indexOf( ".wire" ) != -1)
				{
					wireFile = file;
					break;
				}
			}

			return wireFile;
		}

		private function processWireFile(file:File):CucumberServerInfo
		{
			var serverInfo:CucumberServerInfo = new CucumberServerInfo();

			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);

			var fileString:String = fileStream.readUTFBytes( fileStream.bytesAvailable );
			var getHost:RegExp = /host:\s*?(\S.*)/gi //host:\s*?(\d{0,3}\.){3}\d{0,3}|host:\s*?(localhost)
			var getPort:RegExp = /port:\s*?(\d+)/gi;

			//Note: At some point we are going to have to support getting environment variables
			//Since cucumber can run on ERB so the port declaration will look like
			//port: <%= ENV['PORT'] || 12345 %>

			var host:Object = getHost.exec( fileString );
			var port:Object = getPort.exec( fileString );

			serverInfo.port = int( port[1] );

			return serverInfo;
		}
	}
}