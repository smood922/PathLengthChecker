// ﻿using Alphaleonis.Win32.Filesystem;
using System.IO;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using SearchOption = System.IO.SearchOption;
using System;

namespace PathLengthChecker
{
	/// <summary>
	/// Class used to retrieve file system objects in a given path.
	/// </summary>
	public static class PathRetriever
	{
		/// <summary>
		/// Gets the paths.
		/// </summary>
		/// <param name="searchOptions">The search options to use.</param>
		public static IEnumerable<string> GetPaths(PathSearchOptions searchOptions, CancellationToken cancellationToken)
		{
			if (!Directory.Exists(searchOptions.RootDirectory))
			{
				throw new System.IO.DirectoryNotFoundException($"The specified root directory '{searchOptions.RootDirectory}' does not exist. Please provide a valid directory.");
			}

			// If no Search Pattern was provided, then find everything.
			if (string.IsNullOrEmpty(searchOptions.SearchPattern))
				searchOptions.SearchPattern = "*";

			// Get the paths according to the search parameters
			var paths = GetPathsUsingSystemIO(searchOptions);

			// Return each of the paths, replacing the Root Directory if specified to do so.
			foreach (var path in paths)
			{
				// If we've been asked to stop searching, just return.
				if (cancellationToken.IsCancellationRequested)
					yield break;

				var potentiallyTransformedPath = path;

				if (searchOptions.RootDirectoryReplacement != null)
					potentiallyTransformedPath = potentiallyTransformedPath.Replace(searchOptions.RootDirectory, searchOptions.RootDirectoryReplacement);

				if (searchOptions.UrlEncodePaths)
					potentiallyTransformedPath = System.Uri.EscapeDataString(potentiallyTransformedPath);

				yield return potentiallyTransformedPath;
			}
		}

		private static IEnumerable<string> GetPathsUsingSystemIO(PathSearchOptions searchOptions)
		{
			SearchOption searchOption = searchOptions.SearchOption;

			try
			{
				var paths = Directory.EnumerateFileSystemEntries(
					searchOptions.RootDirectory,
					searchOptions.SearchPattern,
					searchOption
				);

				return paths;
			}
			catch (Exception ex)
			{
				// Handle exceptions, such as access denied, if needed
				Console.WriteLine($"An error occurred: {ex.Message}");
				return Enumerable.Empty<string>();
			}
		}

		private static IEnumerable<string> GetPathsUsingSystemIo(PathSearchOptions searchOptions)
		{
			// Get the paths according to the search parameters
			var paths = Enumerable.Empty<string>();

			switch (searchOptions.TypesToGet)
			{
				default:
				case FileSystemTypes.All:
					paths = Directory.GetFileSystemEntries(searchOptions.RootDirectory, searchOptions.SearchPattern, searchOptions.SearchOption);
					break;

				case FileSystemTypes.Directories:
					paths = Directory.GetDirectories(searchOptions.RootDirectory, searchOptions.SearchPattern, searchOptions.SearchOption);
					break;

				case FileSystemTypes.Files:
					paths = Directory.GetFiles(searchOptions.RootDirectory, searchOptions.SearchPattern, searchOptions.SearchOption);
					break;
			}

			return paths;
		}
	}
}
