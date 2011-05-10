// Written in the D Programming Language, version 2

import std.stdio;
import std.math;
import std.string;

import common;

enum MAX_DISTANCE = 7;

Vector[][MAX_DISTANCE+1] VECTORS_DISTANCE;

void main()
{
	loadData();
	makeMap();

	foreach (byte x; -MAX_DISTANCE..MAX_DISTANCE+1)
		foreach (byte y; -MAX_DISTANCE..MAX_DISTANCE+1)
			foreach (byte z; -MAX_DISTANCE..MAX_DISTANCE+1)
				if (x!=0 || y!=0 || z!=0)
					foreach (distance; 1..MAX_DISTANCE+1)
						if (abs(x) <= distance && abs(y) <= distance && abs(z) <= distance)
							VECTORS_DISTANCE[distance] ~= Vector(x, y, z);

	const(Vector)[][] vectorLevels = new Vector[][3 + MAX_DISTANCE-1+1];
	vectorLevels[1] = VECTORS_CARTESIAN;
	vectorLevels[2] = VECTORS_DIAGONAL;
	foreach (distance; 1..MAX_DISTANCE+1)
		vectorLevels[3 + distance-1] = VECTORS_DISTANCE[distance];
	
	string[] vectorNames = new string[vectorLevels.length];
	vectorNames[0] = "Total blocks";
	vectorNames[1] = "Cartesian, 6 directions";
	vectorNames[2] = " + edges, 6+12 directions";
	vectorNames[3] = " + corners, 6+12+8 directions / all blocks 1 block away";
	foreach (i; 4..vectorLevels.length)
		vectorNames[i] = format("All blocks %d blocks away", i-4+2);
	foreach (i; 1..vectorLevels.length)
		vectorNames[i] ~= format(" (%d blocks total)",  1+vectorLevels[i].length);

	bool[] seen = new bool[diamonds.length];
	int[] counters = new int[vectorLevels.length];
	enum MAX_BOUNTY = 1000;
	int[MAX_BOUNTY][] distribution = new int[MAX_BOUNTY][vectorLevels.length];
	int maxBounty;

	foreach (id, ref d; diamonds)
	{
		if (id % 100 == 0) { writef("%3d%%\r", id*100/diamonds.length); stdout.flush(); }
		int last = 0;
		foreach (level, vectors; vectorLevels)
		{
			int mark(int x, int y, int z)
			{
				int result = 0;
				int id = getDiamondAt(x, y, z);
				if (id>=0 && !seen[id])
				{
					result++;
					seen[id] = true;
					foreach (ref v; vectors)
						result += mark(x+v.x, y+v.y, z+v.z);
				}
				return result;
			}

			seen[] = 0;
			int current = mark(d.tupleof);
			assert(current >= last);
			if (current != last)
			    counters[level]++;
			if (maxBounty < current)
				maxBounty = current;
			distribution[level][current]++;
			last = current;
		}
	}

	foreach (level; 1..counters.length)
		writefln("%6.2f%%  %s", counters[level]*100.0/diamonds.length, vectorNames[level]);

	writeln();
	foreach (bounty; 1..maxBounty+1)
		writef("%5d  ", bounty);
	writeln();
	foreach (level; 1..counters.length)
	{
		foreach (bounty; 1..maxBounty+1)
			if (distribution[level][bounty])
				writef("%5.2f%% ", distribution[level][bounty] * 100.0 / diamonds.length);
			else
				write("    -  ");
		writefln("  %s", vectorNames[level]);
	}
}
