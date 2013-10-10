all: lib testing

lib:
	cd project && haxelib run hxcpp Build.xml
	cd project && haxelib run hxcpp Build.xml -Dfulldebug
	cd project && haxelib run hxcpp Build.xml -DHXCPP_M64
	cd project && haxelib run hxcpp Build.xml -DHXCPP_M64 -Dfulldebug

ios:
	cd project && haxelib run hxcpp Build.xml -Dios
	cd project && haxelib run hxcpp Build.xml -Dios -Dsimulator
	cd project && haxelib run hxcpp Build.xml -Dios -DHXCPP_ARMV7

testing:
	cd test && haxe build.hxml
	# test/bin/NetTest

clean:
	rm -rf ndll
	rm -rf project/obj
	rm project/all_objs
