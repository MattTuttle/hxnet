class TestMain
{
	public static function main()
	{
		var runner = new haxe.unit.TestRunner();

		runner.add(new UdpTest());
		runner.add(new TcpTest());

		runner.run();
	}
}
