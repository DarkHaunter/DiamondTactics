// Written in the D Programming Language, version 2

module common;

import std.stdio;
import std.string;
import std.conv;
import std.algorithm;

enum CHUNK_SIZE = 16;

struct Chunk { int x, z; }
Chunk[] chunks;

struct Diamond { int x, y, z; }
Diamond[] diamonds;

void loadData()
{
	foreach (line; File("chunks.csv").byLine)
	{
		auto chunkStrings = line.chomp().split(",");
		chunks ~= Chunk(to!int(chunkStrings[0]), to!int(chunkStrings[1]));
	}

	foreach (line; File("diamonds.csv").byLine)
	{
		auto diamondStrings = line.chomp().split(",");
		diamonds ~= Diamond(to!int(diamondStrings[0]), to!int(diamondStrings[1]), to!int(diamondStrings[2]));
	}
}

Chunk minChunk, maxChunk;
Diamond minDiamond, maxDiamond, size;
int[] map;

enum NO_DATA = -2;
enum NOT_DIAMOND = -1;

int offsetOf(int x, int y, int z)
{
	return
		(x - minDiamond.x) + 
		(y - minDiamond.y) * size.x + 
		(z - minDiamond.z) * size.y * size.x;
}

void getMinMax(T)(T[] records, out T minRecord, out T maxRecord)
{
	minRecord = records[0];
	maxRecord = records[0];

	foreach (ref record; records[1..$])
		foreach (i, field; record.tupleof)
		{
			minRecord.tupleof[i] = min(minRecord.tupleof[i], field);
			maxRecord.tupleof[i] = max(maxRecord.tupleof[i], field);
		}
}

void makeMap()
{
	getMinMax(diamonds, minDiamond, maxDiamond);
	getMinMax(chunks, minChunk, maxChunk);

	minDiamond.x = minChunk.x * CHUNK_SIZE;
	minDiamond.z = minChunk.z * CHUNK_SIZE;
	maxDiamond.x = maxChunk.x * CHUNK_SIZE + CHUNK_SIZE-1;
	maxDiamond.z = maxChunk.z * CHUNK_SIZE + CHUNK_SIZE-1;

	foreach (i, field; size.tupleof)
		size.tupleof[i] = maxDiamond.tupleof[i] - minDiamond.tupleof[i] + 1;

	map = new int[size.x * size.y * size.z];
	map[] = NOT_DIAMOND;
	foreach (int index, ref diamond; diamonds)
		map[offsetOf(diamond.tupleof)] = index;
}

int getDiamondAt(int x, int y, int z)
{
	if (x < minDiamond.x || y < minDiamond.y || z < minDiamond.z || x > maxDiamond.x || y > maxDiamond.y || z > maxDiamond.z)
		return NO_DATA;
	else
		return map[offsetOf(x, y, z)];
}

auto floorMod(T)(T a, T b) { auto m = a%b; return m>=0 ? m : m + b; }
