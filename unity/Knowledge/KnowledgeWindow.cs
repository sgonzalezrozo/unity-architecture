using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEditor.IMGUI.Controls;
using UnityEngine;
using PackageInfo = UnityEditor.PackageManager.PackageInfo;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// Ventana que muestra las reglas de arquitectura en versión para personas. Sin búsqueda enseña una
    /// portada con los docs generales de cada sección; buscando, todos los docs ordenados por relevancia.
    /// El contenido vive en KnowledgeDocs~ dentro del package y llega a cada proyecto con el submódulo .ai.
    /// Los docs y bloques que dependen de un package solo aparecen si el proyecto lo tiene instalado.
    /// </summary>
    public class KnowledgeWindow : EditorWindow
    {
        private const string MENU_PATH = "Tools/Unity Architecture/Rules Guide";
        private const string DOCS_FOLDER = "KnowledgeDocs~";
        private const string CATALOG_FILE = "knowledge.json";
        private const string PREF_CLOSE_OTHERS = "UnityArchitecture.Knowledge.CloseOthers";
        private const string PREF_SHOW_ALL = "UnityArchitecture.Knowledge.ShowAllPackages";
        private const string PACKAGE_SOURCE_PREFIX = "package:";
        private const float SCROLLBAR_WIDTH = 14f;
        private const float OUTER_PADDING = 10f;
        private const float CARD_PADDING = 16f;
        private const float HEADER_HEIGHT = 44f;
        private const float CHIP_HEIGHT = 22f;
        private const float CHIP_GAP = 6f;

        [SerializeField] private string searchQuery = string.Empty;
        [SerializeField] private string categoryFilter;
        [SerializeField] private string focusedId;
        [SerializeField] private string expandedId;
        [SerializeField] private List<string> openIds = new List<string>();
        [SerializeField] private Vector2 scroll;

        private readonly List<KnowledgeEntry> allEntries = new List<KnowledgeEntry>();
        private readonly List<KnowledgeEntry> filteredEntries = new List<KnowledgeEntry>();
        private readonly List<KnowledgeEntry> sectionBuffer = new List<KnowledgeEntry>();
        private readonly List<HomeSection> homeSections = new List<HomeSection>();
        private readonly List<string> categoryOrder = new List<string>();
        private readonly Dictionary<string, int> categoryCounts = new Dictionary<string, int>();
        private readonly Dictionary<string, string> installedPackages = new Dictionary<string, string>();
        private readonly Stack<NavigationState> history = new Stack<NavigationState>();
        private readonly MarkdownView markdown = new MarkdownView();

        private SearchField searchField;
        private string knowledgeFolder;
        private string loadError;
        private DateTime lastLoadedStamp;
        private float availableWidth;
        private GUIStyle titleStyle, summaryStyle, sectionTitleStyle, sectionDescriptionStyle, chipStyle, emptyStyle;

        [MenuItem(MENU_PATH, priority = 0)]
        public static void OpenWindow()
        {
            var window = GetWindow<KnowledgeWindow>();
            window.titleContent = new GUIContent("Rules Guide", EditorGUIUtility.IconContent("_Help").image);
            window.minSize = new Vector2(460f, 320f);
            window.Show();
        }

        private static bool CloseOthers
        {
            get => EditorPrefs.GetBool(PREF_CLOSE_OTHERS, false);
            set => EditorPrefs.SetBool(PREF_CLOSE_OTHERS, value);
        }

        private static bool ShowAllPackages
        {
            get => EditorPrefs.GetBool(PREF_SHOW_ALL, false);
            set => EditorPrefs.SetBool(PREF_SHOW_ALL, value);
        }

        private bool IsSearching => !string.IsNullOrEmpty((searchQuery ?? string.Empty).Trim());

        private void OnEnable()
        {
            searchField = new SearchField();
            wantsMouseMove = true;
            markdown.LinkClicked += OnLinkClicked;
            Reload();
        }

        private void OnDisable()
        {
            markdown.LinkClicked -= OnLinkClicked;
            markdown.Dispose();
        }

        private void OnFocus()
        {
            if (knowledgeFolder != null && ComputeStamp() != lastLoadedStamp)
                Reload();
        }

        // ------------------------------------------------------------------ Carga

        internal void Reload()
        {
            allEntries.Clear();
            homeSections.Clear();
            loadError = null;
            markdown.ClearTextureCache();
            markdown.EnsureTheme();

            knowledgeFolder = ResolveKnowledgeFolder();
            CollectInstalledPackages();

            KnowledgeCatalog catalog = ReadCatalog();
            if (catalog != null)
            {
                if (catalog.homeSections != null)
                    homeSections.AddRange(catalog.homeSections);

                for (int i = 0; catalog.entries != null && i < catalog.entries.Count; i++)
                {
                    if (ShowAllPackages || MeetsRequirements(catalog.entries[i]))
                        LoadEntry(catalog.entries[i], i);
                }
            }

            BuildCategories();
            lastLoadedStamp = ComputeStamp();
            ApplyFilter();
            Repaint();
        }

        private KnowledgeCatalog ReadCatalog()
        {
            string catalogPath = Path.Combine(knowledgeFolder, CATALOG_FILE);
            if (!File.Exists(catalogPath))
            {
                loadError = $"No se encontró {CATALOG_FILE} en:\n{knowledgeFolder}";
                return null;
            }

            try
            {
                return JsonUtility.FromJson<KnowledgeCatalog>(File.ReadAllText(catalogPath, Encoding.UTF8));
            }
            catch (Exception exception)
            {
                loadError = $"{CATALOG_FILE} no es un JSON válido:\n{exception.Message}";
                return null;
            }
        }

        private void LoadEntry(KnowledgeEntry entry, int index)
        {
            entry.index = index;
            if (string.IsNullOrEmpty(entry.id))
                entry.id = entry.markdownPath ?? index.ToString();

            entry.markdownFullPath = Path.GetFullPath(Path.Combine(knowledgeFolder, entry.markdownPath ?? string.Empty));
            entry.sourceFullPath = ResolveSource(entry.source);

            string raw = File.Exists(entry.markdownFullPath)
                ? File.ReadAllText(entry.markdownFullPath, Encoding.UTF8)
                : $"> [!WARNING] Archivo no encontrado\n> `{entry.markdownPath}`";
            entry.markdownContent = PackageConditions.Apply(raw, installedPackages, ShowAllPackages);

            entry.search = KnowledgeSearch.BuildIndex(entry);
            entry.blocks = MarkdownParser.Parse(entry.markdownContent, markdown.Theme);
            allEntries.Add(entry);
        }

        private void ReparseAll()
        {
            for (int i = 0; i < allEntries.Count; i++)
                allEntries[i].blocks = MarkdownParser.Parse(allEntries[i].markdownContent, markdown.Theme);
        }

        private void CollectInstalledPackages()
        {
            installedPackages.Clear();
            PackageInfo[] packages = PackageInfo.GetAllRegisteredPackages();
            for (int i = 0; i < packages.Length; i++)
                installedPackages[packages[i].name] = packages[i].resolvedPath;
        }

        /// <summary>Un doc con requires solo se muestra si el proyecto tiene esos packages instalados.</summary>
        private bool MeetsRequirements(KnowledgeEntry entry)
        {
            for (int i = 0; entry.requires != null && i < entry.requires.Count; i++)
            {
                if (!installedPackages.ContainsKey(entry.requires[i]))
                    return false;
            }

            for (int i = 0; entry.requiresMissing != null && i < entry.requiresMissing.Count; i++)
            {
                if (installedPackages.ContainsKey(entry.requiresMissing[i]))
                    return false;
            }

            return true;
        }

        private void BuildCategories()
        {
            categoryOrder.Clear();
            categoryCounts.Clear();
            for (int i = 0; i < allEntries.Count; i++)
            {
                string category = CategoryOf(allEntries[i]);
                if (!categoryCounts.ContainsKey(category))
                {
                    categoryOrder.Add(category);
                    categoryCounts[category] = 0;
                }
                categoryCounts[category]++;
            }

            if (categoryFilter != null && !categoryCounts.ContainsKey(categoryFilter))
                categoryFilter = null;
            if (focusedId != null && FindEntry(focusedId) == null)
                focusedId = null;
        }

        private static string CategoryOf(KnowledgeEntry entry)
        {
            return string.IsNullOrEmpty(entry.category) ? "General" : entry.category;
        }

        /// <summary>
        /// La regla original (AGENTS.md, architecture/...) vive en la raíz del repo .ai, un nivel por encima
        /// del package. "package:com.x/README.md" apunta a un archivo de otro package instalado.
        /// </summary>
        private string ResolveSource(string source)
        {
            if (string.IsNullOrEmpty(source))
                return null;

            string fullPath;
            if (source.StartsWith(PACKAGE_SOURCE_PREFIX))
            {
                string rest = source.Substring(PACKAGE_SOURCE_PREFIX.Length);
                int slash = rest.IndexOf('/');
                string packageName = slash < 0 ? rest : rest.Substring(0, slash);
                if (!installedPackages.TryGetValue(packageName, out string packageRoot))
                    return null;
                fullPath = Path.Combine(packageRoot, slash < 0 ? "README.md" : rest.Substring(slash + 1));
            }
            else
            {
                string repoRoot = Path.GetDirectoryName(Path.GetDirectoryName(knowledgeFolder));
                fullPath = Path.GetFullPath(Path.Combine(repoRoot ?? string.Empty, source));
            }

            return File.Exists(fullPath) ? fullPath : null;
        }

        private string ResolveKnowledgeFolder()
        {
            PackageInfo package = PackageInfo.FindForAssembly(typeof(KnowledgeWindow).Assembly);
            if (package != null && !string.IsNullOrEmpty(package.resolvedPath))
                return Path.Combine(package.resolvedPath, DOCS_FOLDER);

            // Fallback: el script está copiado dentro de Assets/. Busca la carpeta junto a él.
            string scriptPath = AssetDatabase.GetAssetPath(MonoScript.FromScriptableObject(this));
            string scriptDir = Path.GetDirectoryName(Path.GetFullPath(FileUtil.GetPhysicalPath(scriptPath)));
            string sibling = Path.Combine(Path.GetDirectoryName(scriptDir) ?? scriptDir, DOCS_FOLDER);
            return Directory.Exists(sibling) ? sibling : Path.Combine(scriptDir, DOCS_FOLDER);
        }

        private DateTime ComputeStamp()
        {
            if (string.IsNullOrEmpty(knowledgeFolder) || !Directory.Exists(knowledgeFolder))
                return DateTime.MinValue;

            DateTime latest = DateTime.MinValue;
            string[] files = Directory.GetFiles(knowledgeFolder, "*.*", SearchOption.AllDirectories);
            for (int i = 0; i < files.Length; i++)
            {
                DateTime time = File.GetLastWriteTimeUtc(files[i]);
                if (time > latest)
                    latest = time;
            }
            return latest;
        }

        private void ApplyFilter()
        {
            filteredEntries.Clear();
            string[] terms = KnowledgeSearch.SplitQuery(searchQuery);

            for (int i = 0; i < allEntries.Count; i++)
            {
                KnowledgeEntry entry = allEntries[i];
                entry.score = KnowledgeSearch.Score(entry, terms);
                if (entry.score > 0f)
                    filteredEntries.Add(entry);
            }

            if (terms.Length > 0)
                filteredEntries.Sort(KnowledgeSearch.CompareByScore);

            if (terms.Length > 0 && filteredEntries.Count == 1)
                SetOpen(filteredEntries[0], true);
        }

        // ------------------------------------------------------------------ Estado de apertura

        private bool IsOpen(KnowledgeEntry entry)
        {
            return CloseOthers ? expandedId == entry.id : openIds.Contains(entry.id);
        }

        private void SetOpen(KnowledgeEntry entry, bool open)
        {
            if (CloseOthers)
            {
                expandedId = open ? entry.id : null;
                return;
            }

            if (open && !openIds.Contains(entry.id))
                openIds.Add(entry.id);
            else if (!open)
                openIds.Remove(entry.id);
        }

        private void CollapseAll()
        {
            openIds.Clear();
            expandedId = null;
        }

        private void GoHome()
        {
            history.Clear();
            SetState(new NavigationState(string.Empty, null, null));
        }

        // ------------------------------------------------------------------ Navegación

        private struct NavigationState
        {
            public readonly string searchQuery;
            public readonly string categoryFilter;
            public readonly string focusedId;
            public readonly Vector2 scroll;

            public NavigationState(string searchQuery, string categoryFilter, string focusedId, Vector2 scroll = default)
            {
                this.searchQuery = searchQuery;
                this.categoryFilter = categoryFilter;
                this.focusedId = focusedId;
                this.scroll = scroll;
            }
        }

        private void NavigateTo(NavigationState state)
        {
            history.Push(new NavigationState(searchQuery, categoryFilter, focusedId, scroll));
            SetState(state);
        }

        private void GoBack()
        {
            if (history.Count > 0)
                SetState(history.Pop());
        }

        private void SetState(NavigationState state)
        {
            searchQuery = state.searchQuery ?? string.Empty;
            categoryFilter = state.categoryFilter;
            focusedId = state.focusedId;
            scroll = state.scroll;
            GUI.FocusControl(null);
            ApplyFilter();
            Repaint();
        }

        /// <summary>"doc:id" abre ese doc, "rule:VIEW-03" el doc que define la regla y una URL el navegador.</summary>
        private void OnLinkClicked(string target)
        {
            if (target.StartsWith("http://") || target.StartsWith("https://"))
            {
                Application.OpenURL(target);
                return;
            }

            KnowledgeEntry entry = ResolveLink(target);
            if (entry == null)
            {
                ShowNotification(new GUIContent("Sin doc para " + target + " en este proyecto"));
                return;
            }

            SetOpen(entry, true);
            NavigateTo(new NavigationState(string.Empty, null, entry.id));
        }

        private KnowledgeEntry ResolveLink(string target)
        {
            if (target.StartsWith(MarkdownParser.RULE_LINK_PREFIX))
                return FindRuleEntry(target.Substring(MarkdownParser.RULE_LINK_PREFIX.Length));

            const string docPrefix = "doc:";
            string id = target.StartsWith(docPrefix) ? target.Substring(docPrefix.Length) : target.TrimStart('#');
            return FindEntry(id);
        }

        private KnowledgeEntry FindEntry(string id)
        {
            for (int i = 0; i < allEntries.Count; i++)
            {
                if (allEntries[i].id == id)
                    return allEntries[i];
            }
            return null;
        }

        /// <summary>El doc que define una regla: el que la tiene en keywords y, si hay varios, la nombra en su resumen.</summary>
        private KnowledgeEntry FindRuleEntry(string ruleId)
        {
            KnowledgeEntry firstWithKeyword = null;
            for (int i = 0; i < allEntries.Count; i++)
            {
                KnowledgeEntry entry = allEntries[i];
                if (!HasKeyword(entry, ruleId))
                    continue;
                if (entry.summary != null && entry.summary.IndexOf(ruleId, StringComparison.OrdinalIgnoreCase) >= 0)
                    return entry;
                if (firstWithKeyword == null)
                    firstWithKeyword = entry;
            }
            return firstWithKeyword;
        }

        private static bool HasKeyword(KnowledgeEntry entry, string keyword)
        {
            for (int i = 0; entry.keywords != null && i < entry.keywords.Count; i++)
            {
                if (string.Equals(entry.keywords[i], keyword, StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            return false;
        }

        // ------------------------------------------------------------------ GUI

        private void OnGUI()
        {
            if (markdown.EnsureStyles())
            {
                ReparseAll();
                titleStyle = null;
            }
            EnsureWindowStyles();

            if (Event.current.type == EventType.MouseMove)
                Repaint();

            DrawToolbar();

            if (loadError != null)
            {
                DrawLoadError();
                return;
            }

            // Sin scroll horizontal: todo se dibuja con el ancho real medido dentro del scroll view.
            scroll = EditorGUILayout.BeginScrollView(scroll, false, true,
                GUIStyle.none, GUI.skin.verticalScrollbar, GUIStyle.none);
            MeasureAvailableWidth();
            float contentWidth = Mathf.Floor(availableWidth - OUTER_PADDING * 2f);
            GUILayout.BeginHorizontal();
            GUILayout.Space(OUTER_PADDING);
            GUILayout.BeginVertical(GUILayout.Width(contentWidth));
            GUILayout.Space(OUTER_PADDING);

            if (IsSearching)
                DrawSearchResults(contentWidth);
            else if (focusedId != null)
                DrawFocusedView(contentWidth);
            else if (categoryFilter != null)
                DrawCategoryView(contentWidth);
            else
                DrawHome(contentWidth);

            GUILayout.Space(OUTER_PADDING);
            GUILayout.EndVertical();
            GUILayout.EndHorizontal();
            EditorGUILayout.EndScrollView();
        }

        /// <summary>
        /// El ancho visible solo se conoce en Repaint. Se guarda para el siguiente frame (Layout y Repaint
        /// tienen que usar el mismo valor) y se repinta si cambió, al redimensionar o al aparecer la barra.
        /// </summary>
        private void MeasureAvailableWidth()
        {
            Rect probe = GUILayoutUtility.GetRect(0f, 0f, GUILayout.ExpandWidth(true));
            if (availableWidth <= 0f)
                availableWidth = position.width - SCROLLBAR_WIDTH;

            if (Event.current.type != EventType.Repaint || probe.width <= 1f)
                return;

            if (Mathf.Abs(probe.width - availableWidth) > 0.5f)
            {
                availableWidth = probe.width;
                Repaint();
            }
        }

        private void EnsureWindowStyles()
        {
            if (titleStyle != null)
                return;

            MdTheme theme = markdown.Theme;
            titleStyle = new GUIStyle(EditorStyles.boldLabel) { fontSize = 13, richText = true, clipping = TextClipping.Clip };
            summaryStyle = new GUIStyle(EditorStyles.label) { fontSize = 11, richText = true, clipping = TextClipping.Clip };
            summaryStyle.normal.textColor = theme.muted;
            sectionTitleStyle = new GUIStyle(EditorStyles.boldLabel) { fontSize = 16, richText = true };
            sectionTitleStyle.normal.textColor = theme.text;
            sectionDescriptionStyle = new GUIStyle(EditorStyles.label) { fontSize = 11, wordWrap = true };
            sectionDescriptionStyle.normal.textColor = theme.muted;
            chipStyle = new GUIStyle(EditorStyles.label)
            {
                fontSize = 11,
                richText = true,
                alignment = TextAnchor.MiddleCenter,
                padding = new RectOffset(10, 10, 0, 0)
            };
            chipStyle.normal.textColor = theme.text;
            emptyStyle = new GUIStyle(EditorStyles.centeredGreyMiniLabel) { fontSize = 12, wordWrap = true };
        }

        private void DrawToolbar()
        {
            GUILayout.BeginHorizontal(EditorStyles.toolbar);

            using (new EditorGUI.DisabledScope(history.Count == 0))
            {
                if (GUILayout.Button(new GUIContent("Atrás", "Volver a donde estabas"), EditorStyles.toolbarButton, GUILayout.Width(46f)))
                    GoBack();
            }

            bool onHome = !IsSearching && categoryFilter == null && focusedId == null;
            using (new EditorGUI.DisabledScope(onHome))
            {
                if (GUILayout.Button(new GUIContent("Inicio", "Volver a la portada"), EditorStyles.toolbarButton, GUILayout.Width(46f)))
                    GoHome();
            }

            EditorGUI.BeginChangeCheck();
            string previousQuery = searchQuery;
            searchQuery = searchField.OnToolbarGUI(searchQuery, GUILayout.ExpandWidth(true));
            if (EditorGUI.EndChangeCheck())
            {
                if (string.IsNullOrEmpty(previousQuery) && (focusedId != null || categoryFilter != null))
                    history.Push(new NavigationState(string.Empty, categoryFilter, focusedId, scroll));
                focusedId = null;
                scroll = Vector2.zero;
                ApplyFilter();
            }

            if (IsSearching)
                GUILayout.Label($"{filteredEntries.Count} resultados", EditorStyles.miniLabel, GUILayout.ExpandWidth(false));

            if (GUILayout.Button(new GUIContent("Colapsar", "Cerrar todos los documentos"), EditorStyles.toolbarButton, GUILayout.Width(60f)))
                CollapseAll();

            GUIContent refresh = EditorGUIUtility.IconContent("Refresh");
            refresh.tooltip = "Recargar knowledge.json y los .md";
            if (GUILayout.Button(refresh, EditorStyles.toolbarButton, GUILayout.Width(28f)))
                Reload();

            GUIContent gear = EditorGUIUtility.IconContent("_Popup");
            gear.tooltip = "Ajustes";
            if (GUILayout.Button(gear, EditorStyles.toolbarButton, GUILayout.Width(28f)))
                PopupWindow.Show(GUILayoutUtility.GetLastRect(), new KnowledgeSettingsPopup(this, knowledgeFolder));

            GUILayout.EndHorizontal();
        }

        private void DrawLoadError()
        {
            GUILayout.Space(10f);
            EditorGUILayout.HelpBox(loadError, MessageType.Warning);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("Recargar"))
                Reload();
            if (Directory.Exists(knowledgeFolder) && GUILayout.Button("Mostrar carpeta"))
                EditorUtility.RevealInFinder(knowledgeFolder);
            GUILayout.EndHorizontal();
        }

        // ------------------------------------------------------------------ Vistas

        private void DrawHome(float width)
        {
            for (int s = 0; s < homeSections.Count; s++)
            {
                CollectSection(homeSections[s].name);
                if (sectionBuffer.Count == 0)
                    continue;

                DrawSectionHeader(homeSections[s].name, homeSections[s].description, width);
                DrawEntryList(sectionBuffer, width);
                GUILayout.Space(14f);
            }

            DrawSectionHeader("Explorar por tema", $"Los {allEntries.Count} docs, agrupados. También puedes escribir arriba lo que buscas, en español o en inglés.", width);
            DrawCategoryChips(width);
        }

        private void CollectSection(string sectionName)
        {
            sectionBuffer.Clear();
            for (int i = 0; i < allEntries.Count; i++)
            {
                if (allEntries[i].home == sectionName)
                    sectionBuffer.Add(allEntries[i]);
            }
            sectionBuffer.Sort(CompareByHomeOrder);
        }

        private static int CompareByHomeOrder(KnowledgeEntry a, KnowledgeEntry b)
        {
            return a.homeOrder.CompareTo(b.homeOrder);
        }

        private void DrawCategoryView(float width)
        {
            sectionBuffer.Clear();
            for (int i = 0; i < allEntries.Count; i++)
            {
                if (CategoryOf(allEntries[i]) == categoryFilter)
                    sectionBuffer.Add(allEntries[i]);
            }

            DrawSectionHeader(categoryFilter, $"{sectionBuffer.Count} docs", width);
            DrawEntryList(sectionBuffer, width);
        }

        /// <summary>Un doc abierto desde un enlace, y debajo los demás de su tema.</summary>
        private void DrawFocusedView(float width)
        {
            KnowledgeEntry focused = FindEntry(focusedId);
            if (focused == null)
                return;

            DrawEntry(focused, width);
            GUILayout.Space(16f);

            sectionBuffer.Clear();
            for (int i = 0; i < allEntries.Count; i++)
            {
                if (allEntries[i] != focused && CategoryOf(allEntries[i]) == CategoryOf(focused))
                    sectionBuffer.Add(allEntries[i]);
            }

            if (sectionBuffer.Count == 0)
                return;

            DrawSectionHeader("Más de " + CategoryOf(focused), null, width);
            DrawEntryList(sectionBuffer, width);
        }

        private void DrawSearchResults(float width)
        {
            if (filteredEntries.Count == 0)
            {
                GUILayout.Space(20f);
                GUILayout.Label("No hay resultados. Prueba con otra palabra, en español o en inglés.", emptyStyle, GUILayout.Width(width));
                return;
            }

            DrawEntryList(filteredEntries, width);
        }

        private void DrawEntryList(List<KnowledgeEntry> entries, float width)
        {
            for (int i = 0; i < entries.Count; i++)
            {
                DrawEntry(entries[i], width);
                GUILayout.Space(6f);
            }
        }

        private void DrawSectionHeader(string title, string description, float width)
        {
            Rect titleRect = GUILayoutUtility.GetRect(width, 24f, GUILayout.Width(width));
            GUI.Label(titleRect, title, sectionTitleStyle);

            if (!string.IsNullOrEmpty(description))
            {
                float height = sectionDescriptionStyle.CalcHeight(new GUIContent(description), width);
                Rect descriptionRect = GUILayoutUtility.GetRect(width, height, GUILayout.Width(width));
                GUI.Label(descriptionRect, description, sectionDescriptionStyle);
            }

            GUILayout.Space(4f);
            Rect line = GUILayoutUtility.GetRect(width, 2f, GUILayout.Width(width));
            if (Event.current.type == EventType.Repaint)
            {
                EditorGUI.DrawRect(line, markdown.Theme.divider);
                EditorGUI.DrawRect(new Rect(line.x, line.y, Mathf.Min(48f, line.width), line.height), markdown.Theme.accent);
            }
            GUILayout.Space(8f);
        }

        /// <summary>Un chip por categoría, en filas que saltan de línea según el ancho.</summary>
        private void DrawCategoryChips(float width)
        {
            float x = 0f;
            int rows = 1;
            for (int i = 0; i < categoryOrder.Count; i++)
            {
                float chipWidth = ChipWidth(categoryOrder[i]);
                if (x > 0f && x + chipWidth > width)
                {
                    rows++;
                    x = 0f;
                }
                x += chipWidth + CHIP_GAP;
            }

            Rect area = GUILayoutUtility.GetRect(width, rows * (CHIP_HEIGHT + CHIP_GAP), GUILayout.Width(width));
            x = 0f;
            float y = 0f;
            for (int i = 0; i < categoryOrder.Count; i++)
            {
                string category = categoryOrder[i];
                float chipWidth = ChipWidth(category);
                if (x > 0f && x + chipWidth > width)
                {
                    x = 0f;
                    y += CHIP_HEIGHT + CHIP_GAP;
                }

                if (DrawChip(new Rect(area.x + x, area.y + y, chipWidth, CHIP_HEIGHT), category))
                    NavigateTo(new NavigationState(string.Empty, category, null));
                x += chipWidth + CHIP_GAP;
            }
        }

        private string ChipLabel(string category)
        {
            return $"{category}  <color=#{ColorUtility.ToHtmlStringRGB(markdown.Theme.muted)}>{categoryCounts[category]}</color>";
        }

        private float ChipWidth(string category)
        {
            return chipStyle.CalcSize(new GUIContent(ChipLabel(category))).x;
        }

        private bool DrawChip(Rect rect, string category)
        {
            Event current = Event.current;
            bool hover = rect.Contains(current.mousePosition);
            MdTheme theme = markdown.Theme;

            if (current.type == EventType.Repaint)
            {
                Color color = theme.EntryColor(CategoryColor(category), 0);
                Color fill = color;
                fill.a = hover ? 0.30f : 0.14f;
                EditorGUI.DrawRect(rect, fill);
                EditorGUI.DrawRect(new Rect(rect.x, rect.y, 3f, rect.height), color);
            }

            GUI.Label(rect, ChipLabel(category), chipStyle);
            if (hover)
                EditorGUIUtility.AddCursorRect(rect, MouseCursor.Link);

            if (current.type == EventType.MouseDown && current.button == 0 && hover)
            {
                current.Use();
                return true;
            }
            return false;
        }

        private string CategoryColor(string category)
        {
            for (int i = 0; i < allEntries.Count; i++)
            {
                if (CategoryOf(allEntries[i]) == category)
                    return allEntries[i].color;
            }
            return null;
        }

        // ------------------------------------------------------------------ Tarjetas

        private void DrawEntry(KnowledgeEntry entry, float width)
        {
            MdTheme theme = markdown.Theme;
            Color color = theme.EntryColor(entry.color, entry.index);
            bool open = IsOpen(entry);

            Rect card = EditorGUILayout.BeginVertical(GUILayout.Width(width));
            if (Event.current.type == EventType.Repaint)
            {
                EditorGUI.DrawRect(card, theme.cardBackground);
                DrawOutline(card, theme.cardBorder);
                EditorGUI.DrawRect(new Rect(card.x, card.y, 4f, card.height), color);
            }

            Rect header = GUILayoutUtility.GetRect(width, HEADER_HEIGHT, GUILayout.Width(width));
            if (DrawEntryHeader(entry, header, open))
                SetOpen(entry, !open);

            if (open)
            {
                Rect divider = GUILayoutUtility.GetRect(width, 1f, GUILayout.Width(width));
                if (Event.current.type == EventType.Repaint)
                    EditorGUI.DrawRect(new Rect(divider.x + 4f, divider.y, divider.width - 4f, 1f), theme.divider);

                GUILayout.Space(10f);
                GUILayout.BeginHorizontal();
                GUILayout.Space(CARD_PADDING + 4f);
                float innerWidth = width - CARD_PADDING * 2f - 4f;
                GUILayout.BeginVertical(GUILayout.Width(innerWidth));
                markdown.Draw(entry.blocks, Path.GetDirectoryName(entry.markdownFullPath), innerWidth);
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
                GUILayout.Space(14f);
            }

            EditorGUILayout.EndVertical();
        }

        /// <summary>Dibuja la cabecera de una tarjeta. Devuelve true si se hizo click para abrir/cerrar.</summary>
        private bool DrawEntryHeader(KnowledgeEntry entry, Rect header, bool open)
        {
            Event current = Event.current;
            bool hover = header.Contains(current.mousePosition);

            if (current.type == EventType.Repaint && hover)
                EditorGUI.DrawRect(new Rect(header.x + 4f, header.y, header.width - 4f, header.height), markdown.Theme.cardHeaderHover);

            Rect sourceRect = new Rect(header.xMax - 30f, header.y + (header.height - 20f) * 0.5f, 22f, 20f);
            if (entry.sourceFullPath != null)
            {
                GUIContent sourceIcon = EditorGUIUtility.IconContent("d_TextAsset Icon");
                sourceIcon.tooltip = "Abrir el original: " + entry.source;
                if (GUI.Button(sourceRect, sourceIcon, EditorStyles.iconButton))
                    EditorUtility.OpenWithDefaultApp(entry.sourceFullPath);
            }

            Rect foldRect = new Rect(header.x + 12f, header.y + 6f, 14f, 16f);
            if (current.type == EventType.Repaint)
                EditorStyles.foldout.Draw(foldRect, false, false, open, false);

            float textX = header.x + 30f;
            float textWidth = sourceRect.x - textX - 6f;
            bool hasSummary = !string.IsNullOrEmpty(entry.summary);
            float titleY = hasSummary ? header.y + 5f : header.y + (header.height - 18f) * 0.5f;
            GUI.Label(new Rect(textX, titleY, textWidth, 18f), entry.title, titleStyle);
            if (hasSummary)
            {
                string summary = categoryFilter == null || IsSearching
                    ? $"<b>{CategoryOf(entry)}</b>  ·  {entry.summary}"
                    : entry.summary;
                GUI.Label(new Rect(textX, header.y + 23f, textWidth, 16f), summary, summaryStyle);
            }

            if (hover)
                EditorGUIUtility.AddCursorRect(new Rect(header.x, header.y, sourceRect.x - header.x, header.height), MouseCursor.Link);

            if (current.type == EventType.MouseDown && current.button == 0 && hover && !sourceRect.Contains(current.mousePosition))
            {
                current.Use();
                return true;
            }
            return false;
        }

        private static void DrawOutline(Rect rect, Color color)
        {
            EditorGUI.DrawRect(new Rect(rect.x, rect.y, rect.width, 1f), color);
            EditorGUI.DrawRect(new Rect(rect.x, rect.yMax - 1f, rect.width, 1f), color);
            EditorGUI.DrawRect(new Rect(rect.xMax - 1f, rect.y, 1f, rect.height), color);
        }

        // ------------------------------------------------------------------ Ajustes

        internal static bool GetShowAll()
        {
            return ShowAllPackages;
        }

        internal void SetShowAll(bool value)
        {
            ShowAllPackages = value;
            Reload();
        }

        internal static bool GetCloseOthers()
        {
            return CloseOthers;
        }

        internal static void SetCloseOthers(bool value)
        {
            CloseOthers = value;
        }
    }

    internal class KnowledgeSettingsPopup : PopupWindowContent
    {
        private readonly KnowledgeWindow owner;
        private readonly string resolvedFolder;

        public KnowledgeSettingsPopup(KnowledgeWindow owner, string resolvedFolder)
        {
            this.owner = owner;
            this.resolvedFolder = resolvedFolder;
        }

        public override Vector2 GetWindowSize()
        {
            return new Vector2(360f, 150f);
        }

        public override void OnGUI(Rect rect)
        {
            GUILayout.Label("Rules Guide", EditorStyles.boldLabel);

            bool closeOthers = EditorGUILayout.ToggleLeft("Abrir un documento cierra los demás", KnowledgeWindow.GetCloseOthers());
            if (closeOthers != KnowledgeWindow.GetCloseOthers())
                KnowledgeWindow.SetCloseOthers(closeOthers);

            bool showAll = EditorGUILayout.ToggleLeft("Mostrar docs de packages no instalados", KnowledgeWindow.GetShowAll());
            if (showAll != KnowledgeWindow.GetShowAll())
                owner.SetShowAll(showAll);

            EditorGUILayout.Space(4f);
            EditorGUILayout.LabelField(resolvedFolder ?? string.Empty, EditorStyles.wordWrappedMiniLabel);
            if (GUILayout.Button("Mostrar carpeta") && Directory.Exists(resolvedFolder))
                EditorUtility.RevealInFinder(Path.Combine(resolvedFolder, "knowledge.json"));
        }
    }
}
