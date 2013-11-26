all: lib ios testing

lib:
	cd project && haxelib run hxcpp Build.xml
	cd project && haxelib run hxcpp Build.xml -Ddebug
	cd project && haxelib run hxcpp Build.xml -DHXCPP_M64
	cd project && haxelib run hxcpp Build.xml -DHXCPP_M64 -Ddebug

ios:
	cd project && haxelib run hxcpp Build.xml -Dios
	cd project && haxelib run hxcpp Build.xml -Dios -Ddebug
	cd project && haxelib run hxcpp Build.xml -Dios -Dsimulator
	cd project && haxelib run hxcpp Build.xml -Dios -Dsimulator -Ddebug
	cd project && haxelib run hxcpp Build.xml -Dios -DHXCPP_ARMV7
	cd project && haxelib run hxcpp Build.xml -Dios -DHXCPP_ARMV7 -Ddebug

testing:
	cd test && haxe build.hxml
	# test/bin/NetTest

clean:
	rm -rf ndll
	rm -rf project/obj
	rm project/all_objs
