HXCPP=haxelib run hxlibc

all: lib ios android testing

lib:
	@cd project && $(HXCPP) Build.xml
	@cd project && $(HXCPP) Build.xml -Ddebug
	@cd project && $(HXCPP) Build.xml -DHXCPP_M64
	@cd project && $(HXCPP) Build.xml -DHXCPP_M64 -Ddebug

ios:
	@cd project && $(HXCPP) Build.xml -Dios
	@cd project && $(HXCPP) Build.xml -Dios -Ddebug
	@cd project && $(HXCPP) Build.xml -Dios -Dsimulator
	@cd project && $(HXCPP) Build.xml -Dios -Dsimulator -Ddebug
	@cd project && $(HXCPP) Build.xml -Dios -DHXCPP_ARMV7
	@cd project && $(HXCPP) Build.xml -Dios -DHXCPP_ARMV7 -Ddebug

android:
	@cd project && $(HXCPP) Build.xml -Dandroid
	@cd project && $(HXCPP) Build.xml -Dandroid -Ddebug

testing:
	cd test && haxe build.hxml
	# test/bin/NetTest

clean:
	rm -rf ndll
	rm -rf project/obj
	rm project/all_objs
