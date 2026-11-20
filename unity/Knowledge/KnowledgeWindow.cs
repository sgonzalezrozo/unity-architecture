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
    /// A window that shows the architecture rules written for people. With no search it shows a
    /// home page with each section's general docs; when searching, every doc ranked by relevance.
    /// The content lives in KnowledgeDocs~ inside the package and reaches each project with the .ai submodule.
    /// Docs and blocks that depend on a package only appear when the project has it installed.
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
        // What the mouse is over (a card header, a chip, a link), so a mouse move repaints only when that changes.
        private string hoverKey;
        private string pendingHoverKey;
        private readonly Dictionary<string, float> chipWidths = new Dictionary<string, float>();
        private readonly Dictionary<string, string> chipLabels = new Dictionary<string, string>();
        private readonly Dictionary<string, string> categoryColors = new Dictionary<string, string>();
        private GUIStyle titleStyle, summaryStyle, sectionTitleStyle, sectionDescriptionStyle, chipStyle, emptyStyle;

        [MenuItem(MENU_PATH, priority = 0)]
        public static void OpenWindow()
        {
            var window = GetWindow<KnowledgeWindow>();
            window.titleContent = new GUIContent(KnowledgeLanguage.T("Rules Guide"), EditorGUIUtility.IconContent("_Help").image);
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

        // ------------------------------------------------------------------ Loading

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
            string catalogPath = Path.Combine(LanguageFolder, CATALOG_FILE);
            if (!File.Exists(catalogPath))
            {
                loadError = $"{CATALOG_FILE} not found in:\n{knowledgeFolder}";
                return null;
            }

            try
            {
                return JsonUtility.FromJson<KnowledgeCatalog>(File.ReadAllText(catalogPath, Encoding.UTF8));
            }
            catch (Exception exception)
            {
                loadError = $"{CATALOG_FILE} isn't valid JSON:\n{exception.Message}";
                return null;
            }
        }

        private void LoadEntry(KnowledgeEntry entry, int index)
        {
            entry.index = index;
            if (string.IsNullOrEmpty(entry.id))
                entry.id = entry.markdownPath ?? index.ToString();

            string englishPath = Path.GetFullPath(Path.Combine(knowledgeFolder, entry.markdownPath ?? string.Empty));
            string translatedPath = Path.GetFullPath(Path.Combine(LanguageFolder, entry.markdownPath ?? string.Empty));
            entry.markdownFullPath = File.Exists(translatedPath) ? translatedPath : englishPath;
            // Images are shared by every language and resolve from the English doc's folder.
            entry.imageFolder = Path.GetDirectoryName(englishPath);
            entry.sourceFullPath = ResolveSource(entry.source);

            string raw = File.Exists(entry.markdownFullPath)
                ? File.ReadAllText(entry.markdownFullPath, Encoding.UTF8)
                : $"> [!WARNING] File not found\n> `{entry.markdownPath}`";
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

            string packageFolder = string.IsNullOrEmpty(knowledgeFolder)
                ? null
                : Path.GetDirectoryName(knowledgeFolder);
            string capabilityTable = Capabilities.FindTable(packageFolder);
            Capabilities.AddTrueCapabilities(capabilityTable, Directory.GetCurrentDirectory(), installedPackages);
        }

        /// <summary>A doc with requires only shows when the project has those packages, or capabilities.</summary>
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
            chipLabels.Clear();
            chipWidths.Clear();
            categoryColors.Clear();
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
            return string.IsNullOrEmpty(entry.category) ? KnowledgeLanguage.T("General") : entry.category;
        }

        /// <summary>
        /// The original rule (AGENTS.md, architecture/...) lives at the root of the .ai repo, one level above
        /// the package. "package:com.x/README.md" points to a file in another installed package.
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

            // Fallback: the script was copied into Assets/. Look for the folder next to it.
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

        // ------------------------------------------------------------------ Open state

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

        // ------------------------------------------------------------------ Navigation

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

        /// <summary>"doc:id" opens that doc, "rule:VIEW-03" the doc that defines the rule, and a URL the browser.</summary>
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
                ShowNotification(new GUIContent(KnowledgeLanguage.T("No doc for {0} in this project", target)));
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

        /// <summary>The doc that defines a rule: the one with it in its keywords and, if several, the one whose summary names it.</summary>
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
                chipLabels.Clear();
                chipWidths.Clear();
                toolNameStyle = null;
            }
            EnsureWindowStyles();

            bool mouseMoved = Event.current.type == EventType.MouseMove;
            if (mouseMoved)
            {
                pendingHoverKey = null;
                markdown.LinkHoverKey = null;
            }

            DrawToolbar();

            if (loadError != null)
            {
                DrawLoadError();
                return;
            }

            // No horizontal scroll: everything is drawn with the real width measured inside the scroll view.
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

            // A mouse move used to repaint the whole window every time. Now it repaints only when the mouse moves onto
            // or off something that draws a hover state.
            if (mouseMoved)
            {
                string key = pendingHoverKey ?? markdown.LinkHoverKey;
                if (key != hoverKey)
                {
                    hoverKey = key;
                    Repaint();
                }
            }
        }

        /// <summary>
        /// The visible width is only known in Repaint. It's kept for the next frame (Layout and Repaint
        /// must use the same value), and the window repaints when it changes, on resize or when the scrollbar appears.
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
                if (GUILayout.Button(new GUIContent(KnowledgeLanguage.T("Back"), KnowledgeLanguage.T("Go back to where you were")), EditorStyles.toolbarButton, GUILayout.Width(46f)))
                    GoBack();
            }

            bool onHome = !IsSearching && categoryFilter == null && focusedId == null;
            using (new EditorGUI.DisabledScope(onHome))
            {
                if (GUILayout.Button(new GUIContent(KnowledgeLanguage.T("Home"), KnowledgeLanguage.T("Go to the home page")), EditorStyles.toolbarButton, GUILayout.Width(46f)))
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
                GUILayout.Label(KnowledgeLanguage.T("{0} results", filteredEntries.Count), EditorStyles.miniLabel, GUILayout.ExpandWidth(false));

            if (GUILayout.Button(new GUIContent(KnowledgeLanguage.T("Collapse"), KnowledgeLanguage.T("Close every doc")), EditorStyles.toolbarButton, GUILayout.Width(60f)))
                CollapseAll();

            GUIContent refresh = EditorGUIUtility.IconContent("Refresh");
            refresh.tooltip = KnowledgeLanguage.T("Reload knowledge.json and the .md files");
            if (GUILayout.Button(refresh, EditorStyles.toolbarButton, GUILayout.Width(28f)))
                Reload();

            GUIContent gear = EditorGUIUtility.IconContent("_Popup");
            gear.tooltip = KnowledgeLanguage.T("Settings");
            if (GUILayout.Button(gear, EditorStyles.toolbarButton, GUILayout.Width(28f)))
                PopupWindow.Show(GUILayoutUtility.GetLastRect(), new KnowledgeSettingsPopup(this, knowledgeFolder));

            GUILayout.EndHorizontal();
        }

        private void DrawLoadError()
        {
            GUILayout.Space(10f);
            EditorGUILayout.HelpBox(loadError, MessageType.Warning);
            GUILayout.BeginHorizontal();
            if (GUILayout.Button(KnowledgeLanguage.T("Reload")))
                Reload();
            if (Directory.Exists(knowledgeFolder) && GUILayout.Button(KnowledgeLanguage.T("Show folder")))
                EditorUtility.RevealInFinder(knowledgeFolder);
            GUILayout.EndHorizontal();
        }

        // ------------------------------------------------------------------ Views

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

            DrawSectionHeader(KnowledgeLanguage.T("Browse by topic"), KnowledgeLanguage.T("All {0} docs, grouped. You can also type what you're looking for above.", allEntries.Count), width);
            DrawCategoryChips(width);

            GUILayout.Space(14f);
            DrawOtherTools(width);
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

        /// <summary>A doc opened from a link, with the rest of its topic below.</summary>
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

            DrawSectionHeader(KnowledgeLanguage.T("More in {0}", CategoryOf(focused)), null, width);
            DrawEntryList(sectionBuffer, width);
        }

        private void DrawSearchResults(float width)
        {
            if (filteredEntries.Count == 0)
            {
                GUILayout.Space(20f);
                GUILayout.Label(KnowledgeLanguage.T("No results. Try another word."), emptyStyle, GUILayout.Width(width));
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

        /// <summary>One chip per category, in rows that wrap to the width.</summary>
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

        /// <summary>Chip labels and widths are measured once per load (and when the styles change), not every frame.</summary>
        private string ChipLabel(string category)
        {
            if (!chipLabels.TryGetValue(category, out string label))
            {
                label = $"{category}  <color=#{ColorUtility.ToHtmlStringRGB(markdown.Theme.muted)}>{categoryCounts[category]}</color>";
                chipLabels[category] = label;
            }
            return label;
        }

        private float ChipWidth(string category)
        {
            if (!chipWidths.TryGetValue(category, out float chipWidth))
            {
                chipWidth = chipStyle.CalcSize(new GUIContent(ChipLabel(category))).x;
                chipWidths[category] = chipWidth;
            }
            return chipWidth;
        }

        private bool DrawChip(Rect rect, string category)
        {
            Event current = Event.current;
            bool hover = rect.Contains(current.mousePosition);
            MdTheme theme = markdown.Theme;
            if (hover && current.type == EventType.MouseMove)
                pendingHoverKey = "chip:" + category;

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
            if (categoryColors.TryGetValue(category, out string color))
                return color;

            for (int i = 0; i < allEntries.Count; i++)
            {
                if (CategoryOf(allEntries[i]) == category)
                {
                    color = allEntries[i].color;
                    break;
                }
            }
            categoryColors[category] = color;
            return color;
        }

        // ------------------------------------------------------------------ Cards

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
                markdown.Draw(entry.blocks, entry.imageFolder, innerWidth);
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
                GUILayout.Space(14f);
            }

            EditorGUILayout.EndVertical();
        }

        /// <summary>Draws a card's header. Returns true when it was clicked to open or close.</summary>
        private bool DrawEntryHeader(KnowledgeEntry entry, Rect header, bool open)
        {
            Event current = Event.current;
            bool hover = header.Contains(current.mousePosition);
            if (hover && current.type == EventType.MouseMove)
                pendingHoverKey = "entry:" + entry.id;

            if (current.type == EventType.Repaint && hover)
                EditorGUI.DrawRect(new Rect(header.x + 4f, header.y, header.width - 4f, header.height), markdown.Theme.cardHeaderHover);

            Rect sourceRect = new Rect(header.xMax - 30f, header.y + (header.height - 20f) * 0.5f, 22f, 20f);
            if (entry.sourceFullPath != null)
            {
                GUIContent sourceIcon = EditorGUIUtility.IconContent("d_TextAsset Icon");
                sourceIcon.tooltip = KnowledgeLanguage.T("Open the original: {0}", entry.source);
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

        // ------------------------------------------------------------------ Settings

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

        internal void SetLanguage(string code)
        {
            KnowledgeLanguage.Current = code;
            titleContent = new GUIContent(KnowledgeLanguage.T("Rules Guide"), titleContent.image);
            history.Clear();
            Reload();
        }

        /// <summary>The folder the catalog and docs are read from: es/ for Spanish when it's there, the English root otherwise.</summary>
        private string LanguageFolder
        {
            get
            {
                if (KnowledgeLanguage.IsSpanish)
                {
                    string spanish = Path.Combine(knowledgeFolder, KnowledgeLanguage.SPANISH);
                    if (File.Exists(Path.Combine(spanish, CATALOG_FILE)))
                        return spanish;
                }
                return knowledgeFolder;
            }
        }

        // ------------------------------------------------------------------ Other tools

        private struct OtherTool
        {
            public string Name;
            public string Package;
            public string Repository;
            public string English;
            public string Spanish;
            // A Git dependency Unity doesn't install on its own: its name and URL, added before this package.
            public string DependencyName;
            public string DependencyUrl;
        }

        private static readonly OtherTool[] OtherTools =
        {
            new OtherTool { Name = "Tools Core", Package = "com.sgonzalezrozo.core", Repository = "unity-tools-core",
                English = "Shared dependency injection interfaces. Needed by Screen System, Fast IoC and UI Scroller: add it first.",
                Spanish = "Interfaces compartidas de inyección de dependencias. La necesitan Screen System, Fast IoC y UI Scroller: añádela primero." },
            new OtherTool { Name = "Fast IoC", Package = "com.sgonzalezrozo.fast-ioc", Repository = "unity-fast-ioc",
                English = "Dependency injection with generated code and no runtime reflection.",
                Spanish = "Inyección de dependencias con código generado y sin reflexión en runtime." },
            new OtherTool { Name = "Screen System", Package = "com.sgonzalezrozo.screen-system", Repository = "unity-screen-system",
                English = "Layer-based UI navigation for uGUI and UI Toolkit: screens, modals and alerts.",
                Spanish = "Navegación de UI por layers para uGUI y UI Toolkit: pantallas, modales y alertas." },
            new OtherTool { Name = "UI Scroller", Package = "com.sgonzalezrozo.ui-scroller", Repository = "unity-ui-scroller",
                English = "Recycling scroll view for lists, grids and bento layouts of any length.",
                Spanish = "Scroll con reciclado para listas, grids y layouts bento de cualquier tamaño." },
            new OtherTool { Name = "UI Foundations", Package = "com.sgonzalezrozo.ui-foundations", Repository = "unity-ui-foundations",
                English = "Click Controllers, view states and group gradients for strict MVC.",
                Spanish = "Click Controllers, estados de vista y gradientes de grupo para MVC estricto." },
            new OtherTool { Name = "UI Tweens", Package = "com.sgonzalezrozo.ui-tweens", Repository = "unity-ui-tweens",
                English = "ECS-based tweens for Unity UI with a DOTween-style API.",
                Spanish = "Tweens basados en ECS para la UI de Unity, con una API estilo DOTween.",
                DependencyName = "LeoECS Core",
                DependencyUrl = "https://github.com/LeoECSCommunity/ecs.git#91cc7e390fa0eb4fc88a5cf111df88b1f45af37e" },
            new OtherTool { Name = "Enhanced Console", Package = "com.sgonzalezrozo.enhanced-console", Repository = "unity-enhanced-console",
                English = "An Editor console for noisy logs: filter by system with sections or regex, search stack traces, timestamps. Editor-only.",
                Spanish = "Una consola del Editor para logs ruidosos: filtra por sistema con secciones o regex, busca en stack traces, marcas de tiempo. Solo Editor." },
        };

        private GUIStyle toolNameStyle, toolTextStyle, toolUrlStyle, installedStyle;

        /// <summary>A Git dependency to add first, with its own Copy URL button. Unity doesn't install Git dependencies.</summary>
        private void DrawDependency(OtherTool tool, float width)
        {
            GUILayout.BeginHorizontal(GUILayout.Width(width));
            GUILayout.Label(KnowledgeLanguage.T("Needs {0}: add it first, or Unity reports compile errors.", tool.DependencyName), toolTextStyle);
            GUILayout.FlexibleSpace();
            if (GUILayout.Button(KnowledgeLanguage.T("Copy URL"), EditorStyles.miniButton, GUILayout.ExpandWidth(false)))
            {
                EditorGUIUtility.systemCopyBuffer = tool.DependencyUrl;
                ShowNotification(new GUIContent(KnowledgeLanguage.T("Copied {0}", tool.DependencyUrl)));
            }
            GUILayout.EndHorizontal();
            EditorGUILayout.SelectableLabel(tool.DependencyUrl, toolUrlStyle, GUILayout.Width(width), GUILayout.Height(14f));
        }

        /// <summary>The author's other packages, each with its git URL, marked Installed when the project has it.</summary>
        private void DrawOtherTools(float width)
        {
            DrawSectionHeader(KnowledgeLanguage.T("Other tools"), KnowledgeLanguage.T("The author's other Unity packages. Install one from Window > Package Manager > + > Add package from git URL."), width);

            if (toolNameStyle == null)
            {
                toolNameStyle = new GUIStyle(EditorStyles.boldLabel) { fontSize = 12 };
                toolTextStyle = new GUIStyle(EditorStyles.wordWrappedLabel) { fontSize = 11 };
                toolUrlStyle = new GUIStyle(EditorStyles.miniLabel) { fontSize = 10 };
                installedStyle = new GUIStyle(EditorStyles.miniBoldLabel) { normal = { textColor = new Color(0.25f, 0.73f, 0.31f) } };
            }

            MdTheme theme = markdown.Theme;
            for (int i = 0; i < OtherTools.Length; i++)
            {
                OtherTool tool = OtherTools[i];
                string url = $"https://github.com/sgonzalezrozo/{tool.Repository}.git";
                string text = KnowledgeLanguage.IsSpanish ? tool.Spanish : tool.English;
                bool installed = installedPackages.ContainsKey(tool.Package);

                Rect card = EditorGUILayout.BeginVertical(GUILayout.Width(width));
                if (Event.current.type == EventType.Repaint)
                {
                    EditorGUI.DrawRect(card, theme.cardBackground);
                    DrawOutline(card, theme.cardBorder);
                }

                GUILayout.Space(6f);
                GUILayout.BeginHorizontal();
                GUILayout.Space(CARD_PADDING);
                GUILayout.Label(tool.Name, toolNameStyle, GUILayout.ExpandWidth(false));
                if (installed)
                    GUILayout.Label("✓ " + KnowledgeLanguage.T("Installed"), installedStyle, GUILayout.ExpandWidth(false));
                GUILayout.FlexibleSpace();
                if (!installed && GUILayout.Button(KnowledgeLanguage.T("Copy URL"), EditorStyles.miniButton, GUILayout.ExpandWidth(false)))
                {
                    EditorGUIUtility.systemCopyBuffer = url;
                    ShowNotification(new GUIContent(KnowledgeLanguage.T("Copied {0}", url)));
                }
                GUIContent open = EditorGUIUtility.IconContent("_Help");
                open.tooltip = KnowledgeLanguage.T("Open the repository");
                if (GUILayout.Button(open, EditorStyles.iconButton, GUILayout.Width(20f)))
                    Application.OpenURL($"https://github.com/sgonzalezrozo/{tool.Repository}#readme");
                GUILayout.Space(CARD_PADDING);
                GUILayout.EndHorizontal();

                float innerWidth = width - CARD_PADDING * 2f;
                GUILayout.BeginHorizontal();
                GUILayout.Space(CARD_PADDING);
                GUILayout.BeginVertical(GUILayout.Width(innerWidth));
                GUILayout.Label(text, toolTextStyle, GUILayout.Width(innerWidth));
                // Once the package is installed, its dependency is already there.
                if (!installed && !string.IsNullOrEmpty(tool.DependencyUrl))
                    DrawDependency(tool, innerWidth);
                EditorGUILayout.SelectableLabel(url, toolUrlStyle, GUILayout.Width(innerWidth), GUILayout.Height(14f));
                GUILayout.EndVertical();
                GUILayout.EndHorizontal();
                GUILayout.Space(6f);
                EditorGUILayout.EndVertical();
                GUILayout.Space(6f);
            }
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
            return new Vector2(360f, 176f);
        }

        public override void OnGUI(Rect rect)
        {
            GUILayout.Label(KnowledgeLanguage.T("Rules Guide"), EditorStyles.boldLabel);

            int language = Array.IndexOf(KnowledgeLanguage.Codes, KnowledgeLanguage.Current);
            int chosen = EditorGUILayout.Popup(KnowledgeLanguage.T("Language"), Mathf.Max(0, language), KnowledgeLanguage.Labels);
            if (chosen != language)
                owner.SetLanguage(KnowledgeLanguage.Codes[chosen]);

            bool closeOthers = EditorGUILayout.ToggleLeft(KnowledgeLanguage.T("Opening a doc closes the others"), KnowledgeWindow.GetCloseOthers());
            if (closeOthers != KnowledgeWindow.GetCloseOthers())
                KnowledgeWindow.SetCloseOthers(closeOthers);

            bool showAll = EditorGUILayout.ToggleLeft(KnowledgeLanguage.T("Show docs of packages that aren't installed"), KnowledgeWindow.GetShowAll());
            if (showAll != KnowledgeWindow.GetShowAll())
                owner.SetShowAll(showAll);

            EditorGUILayout.Space(4f);
            EditorGUILayout.LabelField(resolvedFolder ?? string.Empty, EditorStyles.wordWrappedMiniLabel);
            if (GUILayout.Button(KnowledgeLanguage.T("Show folder")) && Directory.Exists(resolvedFolder))
                EditorUtility.RevealInFinder(Path.Combine(resolvedFolder, "knowledge.json"));
        }
    }
}
