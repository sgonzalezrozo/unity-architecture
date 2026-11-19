using System;
using System.Collections.Generic;

#pragma warning disable CS0649 // Fields assigned by JsonUtility

namespace UnityArchitecture.Knowledge
{
    /// <summary>The contents of knowledge.json: the index of docs the window shows.</summary>
    [Serializable]
    internal class KnowledgeCatalog
    {
        public int version = 1;
        public List<HomeSection> homeSections = new List<HomeSection>();
        public List<KnowledgeEntry> entries = new List<KnowledgeEntry>();
    }

    /// <summary>A home page section: the general docs shown when nothing is searched.</summary>
    [Serializable]
    internal class HomeSection
    {
        public string name;
        public string description;
    }

    [Serializable]
    internal class KnowledgeEntry
    {
        public string id;
        public string title;
        public string summary;
        public string category;
        public string color;
        public List<string> keywords = new List<string>();
        public string markdownPath;
        public string source;
        public string home;
        public int homeOrder;
        public List<string> requires = new List<string>();
        public List<string> requiresMissing = new List<string>();

        [NonSerialized] public string markdownContent;
        [NonSerialized] public string markdownFullPath;
        [NonSerialized] public string sourceFullPath;
        [NonSerialized] public List<MdBlock> blocks;
        [NonSerialized] public int index;
        [NonSerialized] public float score;
        [NonSerialized] public SearchIndex search;
    }

    /// <summary>Normalized text (lowercase, no accents) for fast search.</summary>
    internal class SearchIndex
    {
        public string title;
        public string summary;
        public string category;
        public string body;
        public string[] keywords;
        public string[] words;
    }
}
