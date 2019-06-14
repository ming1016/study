package org.yinwang.rubysonar;

import org.junit.Assert;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;

import java.util.ArrayList;

public class _Test {

@Rule public final ExpectedException thrown = ExpectedException.none();

  @Test
  public void testSame() {
    Assert.assertTrue(_.same(null, null));
    Assert.assertTrue(_.same(1, 1));
    Assert.assertFalse(_.same(1, 0));
  }

  @Test
  public void testGetQnameParent() {
    Assert.assertEquals("", _.getQnameParent(null));
    Assert.assertEquals("", _.getQnameParent(""));
    Assert.assertEquals("", _.getQnameParent("1234"));
    Assert.assertEquals(
      "...............",
      _.getQnameParent("................?????????????"));
  }

  @Test
  public void testMainName() {
    thrown.expect(NullPointerException.class);
    _.mainName(null);
    // Method is not expected to return due to exception thrown
  }

  @Test
  public void testArrayToString() {
    final ArrayList<String> strings = new ArrayList<String>();
    Assert.assertEquals("", _.arrayToString(strings));

    strings.add("foo");
    strings.add("bar");
    Assert.assertEquals("foo\nbar\n", _.arrayToString(strings));
  }

  @Test
  public void testEscapeWindowsPath() {
    Assert.assertEquals("\\\\a\\\\b\\\\c", _.escapeWindowsPath("\\a\\b\\c"));
  }

  @Test
  public void testToStringCollection() {
    final ArrayList<Integer> collection = new ArrayList<Integer>();
    final ArrayList<String> arrayList = new ArrayList<String>();
    Assert.assertEquals(arrayList, _.toStringCollection(collection));

    collection.add(-10_000_000);
    arrayList.add("-10000000");
    Assert.assertEquals(arrayList, _.toStringCollection(collection));
  }

  @Test
  public void testPercent() {
    Assert.assertEquals("100%", _.percent(0L, 0L));
    Assert.assertEquals(" 10%", _.percent(20L, 200L));
  }

  @Test
  public void testFormatTime() {
    Assert.assertEquals("6:9:3", _.formatTime(22_143_064L));
  }

  @Test
  public void testFormatNumber() {
    Assert.assertEquals("2 ", _.formatNumber(2L, -2));
    Assert.assertEquals("7 ", _.formatNumber(7, -2));
    Assert.assertEquals("7", _.formatNumber(7, 0));

    thrown.expect(NullPointerException.class);
    _.formatNumber(null, 8);
    // Method is not expected to return due to exception thrown
  }
}
