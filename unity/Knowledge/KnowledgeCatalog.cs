using System;
using System.Collections.Generic;

#pragma warning disable CS0649 // Campos asignados por JsonUtility

namespace UnityArchitecture.Knowledge
{
    /// <summary>Contenido de knowledge.json: el índice de documentos que muestra la ventana.</summary>
    [Serializable]
    internal class KnowledgeCatalog
    {
        public int version = 1;
        public List<HomeSection> homeSections = new List<HomeSection>();
        public List<KnowledgeEntry> entries = new List<KnowledgeEntry>();
    }

    /// <summary>Una sección de la portada: los docs generales que se ven sin buscar.</summary>
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

    /// <summary>Textos normalizados (minúsculas, sin tildes) para buscar rápido.</summary>
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
