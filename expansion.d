// Written in the D Programming Language, version 2

import std.stdio;
import std.math;
import std.string;

import common;

struct Vector { int x, y, z; }

const Vector[] VECTORS_CARTESIAN = [
	{-1,  0,  0},
	{ 1,  0,  0},
	{ 0, -1,  0},
	{ 0,  1,  0},
	{ 0,  0, -1},
	{ 0,  0,  1},
];

const Vector[] VECTORS_DIAGONAL = [
	{-1, -1,  0},
	{-1,  1,  0},
	{ 1, -1,  0},
	{ 1,  1,  0},
	{-1,  0, -1},
	{-1,  0,  1},
	{ 1,  0, -1},
	{ 1,  0,  1},
	{ 0, -1, -1},
	{ 0, -1,  1},
	{ 0,  1, -1},
	{ 0,  1,  1},
];

enum MAX_DISTANCE = 6;

Vector[][MAX_DISTANCE+1] VECTORS_DISTANCE;

void main()
{
	loadData();
	makeMap();

	foreach (x; -MAX_DISTANCE..MAX_DISTANCE+1)
		foreach (y; -MAX_DISTANCE..MAX_DISTANCE+1)
			foreach (z; -MAX_DISTANCE..MAX_DISTANCE+1)
				if (x!=0 || y!=0 || z!=0)
					foreach (distance; 1..MAX_DISTANCE+1)
						if (abs(x) <= distance && abs(y) <= distance && abs(z) <= distance)
							VECTORS_DISTANCE[distance] ~= Vector(x, y, z);

	const(Vector)[][] vectorLevels = new Vector[][3 + MAX_DISTANCE-1+1];
	vectorLevels[1] = VECTORS_CARTESIAN;
	vectorLevels[2] = VECTORS_CARTESIAN ~ VECTORS_DIAGONAL;
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

	foreach (ref d; diamonds)
	{
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
			last = current;
		}
	}

	foreach (i; 1..counters.length)
		writefln("%6.2f%%  %s", counters[i]*100.0/diamonds.length, vectorNames[i]);
}
