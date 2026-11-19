using System.Collections.Generic;
using UnityEditor;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// The Rules Guide's language, chosen in its settings. English docs live in KnowledgeDocs~/, Spanish ones in
    /// KnowledgeDocs~/es/ with the same paths and ids; a doc missing in Spanish falls back to English. The window's own
    /// labels are translated here.
    /// </summary>
    internal static class KnowledgeLanguage
    {
        public const string ENGLISH = "en";
        public const string SPANISH = "es";

        private const string PREF_LANGUAGE = "UnityArchitecture.Knowledge.Language";

        public static readonly string[] Codes = { ENGLISH, SPANISH };
        public static readonly string[] Labels = { "English", "Español" };

        private static readonly Dictionary<string, string> Spanish = new Dictionary<string, string>
        {
            { "Back", "Atrás" },
            { "Go back to where you were", "Volver a donde estabas" },
            { "Home", "Inicio" },
            { "Go to the home page", "Ir a la página de inicio" },
            { "Collapse", "Plegar" },
            { "Close every doc", "Cierra todos los docs" },
            { "Reload knowledge.json and the .md files", "Recarga knowledge.json y los .md" },
            { "Settings", "Ajustes" },
            { "Reload", "Recargar" },
            { "Show folder", "Mostrar carpeta" },
            { "{0} results", "{0} resultados" },
            { "Browse by topic", "Explorar por tema" },
            { "All {0} docs, grouped. You can also type what you're looking for above.", "Los {0} docs, agrupados. También puedes escribir arriba lo que buscas." },
            { "More in {0}", "Más en {0}" },
            { "No results. Try another word.", "Sin resultados. Prueba con otra palabra." },
            { "Open the original: {0}", "Abrir el original: {0}" },
            { "No doc for {0} in this project", "No hay doc para {0} en este proyecto" },
            { "Rules Guide", "Guía de reglas" },
            { "Language", "Idioma" },
            { "Opening a doc closes the others", "Abrir un doc cierra los demás" },
            { "Show docs of packages that aren't installed", "Mostrar docs de packages no instalados" },
            { "Other tools", "Otras herramientas" },
            { "The author's other Unity packages. Install one from Window > Package Manager > + > Add package from git URL.", "Los otros packages de Unity del autor. Instala uno desde Window > Package Manager > + > Add package from git URL." },
            { "Installed", "Instalado" },
            { "Copy URL", "Copiar URL" },
            { "Copied {0}", "Copiado {0}" },
            { "Open the repository", "Abrir el repositorio" },
            { "General", "General" },
        };

        public static string Current
        {
            get => EditorPrefs.GetString(PREF_LANGUAGE, ENGLISH);
            set => EditorPrefs.SetString(PREF_LANGUAGE, value);
        }

        public static bool IsSpanish => Current == SPANISH;

        /// <summary>The window label <paramref name="english"/> in the chosen language.</summary>
        public static string T(string english)
        {
            if (IsSpanish && Spanish.TryGetValue(english, out string translated))
                return translated;
            return english;
        }

        /// <summary><see cref="T"/> for a label with {0}.</summary>
        public static string T(string english, object argument)
            => string.Format(T(english), argument);
    }
}
