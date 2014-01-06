class NetTest
{
	public static function main()
	{
		var runner = new haxe.unit.TestRunner();

		#if (mac || ios)
		runner.add(new BonjourTest());
		#end

		runner.add(new UdpTest());
		runner.add(new TcpTest());

		runner.run();
	}
}
