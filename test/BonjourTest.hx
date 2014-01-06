import hxnet.zeroconf.Bonjour;

class BonjourTest extends haxe.unit.TestCase
{
	public override function setup()
	{
		trace("setup");
		bonjour = new Bonjour("local.", "http.tcp.", "web");
		bonjour.addEventListener(Bonjour.WILL_PUBLISH, didPublish);
		bonjour.addEventListener(Bonjour.DID_PUBLISH, didPublish);
	}

	private function didPublish(e:BonjourService)
	{
		trace(e);
	}

	public function testPublish()
	{
		bonjour.publish(2000);
		Sys.sleep(2);
		assertTrue(true);
	}

	public function testDiscover()
	{
		bonjour.resolve();
		assertTrue(true);
	}

	private var bonjour:Bonjour;
}