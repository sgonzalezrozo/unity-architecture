using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// Draws <see cref="MarkdownParser"/> blocks with IMGUI. Everything is drawn with an explicit width
    /// so wrapped text computes its height correctly.
    /// </summary>
    internal sealed class MarkdownView : IDisposable
    {
        private const float LIST_INDENT = 18f;
        private const float CODE_HEADER_HEIGHT = 20f;
        private const float FLOW_GAP = 8f;
        private const float FLOW_ARROW_WIDTH = 22f;
        private const string MONO_FONT_PATH = "Fonts/RobotoMono/RobotoMono-Regular.ttf";

        private readonly Dictionary<string, Texture2D> textures = new Dictionary<string, Texture2D>();
        private readonly GUIContent tempContent = new GUIContent();

        private Font monoFont;
        private MdTheme theme;
        private MdBlock lastCopied;

        private GUIStyle h1, h2, h3, h4, body, marker, code, codeLang, tableCell, tableHeader;
        private GUIStyle caption, calloutTitle, calloutBox, flowStep, flowArrow, placeholder;

        private static int indexMode = -1;

        /// <summary>Raised when a link is clicked: "doc:id", "rule:VIEW-03" or a URL.</summary>
        public event Action<string> LinkClicked;

        public MdTheme Theme => theme;

        /// <summary>Returns true if the skin changed and the docs must be parsed again (colors are baked into the text).</summary>
        // The theme parsing needs. Safe in OnEnable: unlike the styles, it doesn't read EditorStyles, which isn't ready yet.
        public void EnsureTheme()
        {
            bool dark = EditorGUIUtility.isProSkin;
            if (theme == null || theme.dark != dark)
                theme = new MdTheme(dark);
        }

        public bool EnsureStyles()
        {
            bool dark = EditorGUIUtility.isProSkin;
            if (theme != null && theme.dark == dark && body != null)
                return false;

            bool skinChanged = theme != null && theme.dark != dark;
            theme = new MdTheme(dark);
            BuildStyles();
            return skinChanged;
        }

        public void Dispose()
        {
            foreach (KeyValuePair<string, Texture2D> pair in textures)
            {
                if (pair.Value != null)
                    UnityEngine.Object.DestroyImmediate(pair.Value);
            }
            textures.Clear();
        }

        public void ClearTextureCache()
        {
            Dispose();
            body = null;
        }

        private void BuildStyles()
        {
            // The monospace font that ships with the Editor. It's a persistent asset: a font created at runtime
            // (CreateDynamicFontFromOSFont) leaves invalid references after a script reload.
            if (monoFont == null)
                monoFont = EditorGUIUtility.Load(MONO_FONT_PATH) as Font;

            body = Make(EditorStyles.label, 12, FontStyle.Normal, theme.text);
            body.wordWrap = true;

            h1 = Make(EditorStyles.label, 20, FontStyle.Bold, theme.text);
            h2 = Make(EditorStyles.label, 16, FontStyle.Bold, theme.text);
            h3 = Make(EditorStyles.label, 13, FontStyle.Bold, theme.heading3);
            h4 = Make(EditorStyles.label, 12, FontStyle.Bold, theme.muted);
            h1.wordWrap = h2.wordWrap = h3.wordWrap = h4.wordWrap = true;

            marker = Make(EditorStyles.label, 12, FontStyle.Bold, theme.accent);
            marker.alignment = TextAnchor.UpperRight;

            code = Make(EditorStyles.label, 12, FontStyle.Normal, theme.text);
            code.font = monoFont;
            code.wordWrap = true;
            code.padding = new RectOffset(10, 10, 8, 8);

            codeLang = Make(EditorStyles.miniLabel, 10, FontStyle.Bold, theme.muted);
            codeLang.alignment = TextAnchor.MiddleLeft;
            codeLang.padding = new RectOffset(8, 4, 0, 0);

            tableCell = Make(EditorStyles.label, 11, FontStyle.Normal, theme.text);
            tableCell.wordWrap = true;
            tableCell.padding = new RectOffset(7, 7, 5, 5);

            tableHeader = new GUIStyle(tableCell) { fontStyle = FontStyle.Bold };

            caption = Make(EditorStyles.label, 11, FontStyle.Italic, theme.muted);
            caption.wordWrap = true;
            caption.alignment = TextAnchor.UpperCenter;

            calloutTitle = Make(EditorStyles.label, 12, FontStyle.Bold, theme.text);
            calloutTitle.alignment = TextAnchor.MiddleLeft;

            calloutBox = new GUIStyle { padding = new RectOffset(14, 10, 8, 8), margin = new RectOffset(0, 0, 0, 0) };

            flowStep = Make(EditorStyles.label, 12, FontStyle.Bold, theme.text);
            flowStep.alignment = TextAnchor.MiddleCenter;
            flowStep.padding = new RectOffset(12, 12, 7, 7);

            flowArrow = Make(EditorStyles.label, 16, FontStyle.Bold, theme.muted);
            flowArrow.alignment = TextAnchor.MiddleCenter;

            placeholder = Make(EditorStyles.label, 11, FontStyle.Normal, theme.muted);
            placeholder.alignment = TextAnchor.MiddleCenter;
            placeholder.wordWrap = true;
        }

        private static GUIStyle Make(GUIStyle source, int size, FontStyle fontStyle, Color color)
        {
            var style = new GUIStyle(source)
            {
                fontSize = size,
                fontStyle = fontStyle,
                richText = true,
                margin = new RectOffset(0, 0, 0, 0),
                padding = new RectOffset(0, 0, 0, 0)
            };
            style.normal.textColor = color;
            style.hover.textColor = color;
            style.active.textColor = color;
            style.focused.textColor = color;
            return style;
        }

        // ------------------------------------------------------------------ Entry point

        public void Draw(List<MdBlock> blocks, string docDir, float width)
        {
            if (blocks == null)
                return;

            MdBlockType previous = MdBlockType.Paragraph;
            for (int i = 0; i < blocks.Count; i++)
            {
                MdBlock block = blocks[i];
                if (i > 0)
                    GUILayout.Space(SpacingBefore(block, previous));
                DrawBlock(block, docDir, width);
                previous = block.type;
            }
        }

        private static float SpacingBefore(MdBlock block, MdBlockType previous)
        {
            if (block.type == MdBlockType.ListItem && previous == MdBlockType.ListItem)
                return 3f;
            if (block.type == MdBlockType.Heading)
                return block.level <= 2 ? 16f : 10f;
            return 8f;
        }

        private void DrawBlock(MdBlock block, string docDir, float width)
        {
            switch (block.type)
            {
                case MdBlockType.Heading: DrawHeading(block, width); break;
                case MdBlockType.Paragraph: WrappedLabel(block.text, body, width, block.links); break;
                case MdBlockType.ListItem: DrawListItem(block, width); break;
                case MdBlockType.Code: DrawCode(block, width); break;
                case MdBlockType.Callout: DrawCallout(block, docDir, width); break;
                case MdBlockType.Table: DrawTable(block, width); break;
                case MdBlockType.Rule: DrawRule(width); break;
                case MdBlockType.Image: DrawImage(block, docDir, width); break;
                case MdBlockType.Flow: DrawFlow(block, width); break;
            }
        }

        // ------------------------------------------------------------------ Blocks

        private Rect WrappedLabel(string text, GUIStyle style, float width, List<MdLink> links = null)
        {
            GUIContent content = Temp(text);
            float height = style.CalcHeight(content, width);
            Rect rect = GUILayoutUtility.GetRect(width, height, GUILayout.Width(width));
            GUI.Label(rect, content, style);
            HandleLinks(rect, content, style, links);
            return rect;
        }

        // ------------------------------------------------------------------ Links

        /// <summary>
        /// IMGUI has no links inside a label: find the character under the mouse and whether it falls
        /// inside a link. Shows the hand cursor on hover and raises LinkClicked on click.
        /// </summary>
        private void HandleLinks(Rect rect, GUIContent content, GUIStyle style, List<MdLink> links)
        {
            if (links == null || links.Count == 0)
                return;

            Event current = Event.current;
            bool isClick = current.type == EventType.MouseDown && current.button == 0;
            if ((current.type != EventType.Repaint && !isClick) || !rect.Contains(current.mousePosition))
                return;

            MdLink link = FindLinkAt(rect, content, style, links, current.mousePosition);
            if (link == null)
                return;

            if (current.type == EventType.Repaint)
            {
                EditorGUIUtility.AddCursorRect(rect, MouseCursor.Link);
                return;
            }

            current.Use();
            if (LinkClicked != null)
                LinkClicked(link.target);
        }

        private static MdLink FindLinkAt(Rect rect, GUIContent content, GUIStyle style, List<MdLink> links, Vector2 mouse)
        {
            int index = style.GetCursorStringIndex(rect, content, mouse);
            bool rawIndices = UsesRawIndices(style);

            for (int i = 0; i < links.Count; i++)
            {
                int start = rawIndices ? links[i].start : links[i].visibleStart;
                int end = rawIndices ? links[i].end : links[i].visibleEnd;
                if (index >= start && index < end)
                    return links[i];
            }
            return null;
        }

        /// <summary>
        /// Depending on the Unity version, the cursor index counts rich text tags or not. Checked
        /// once: with raw indices, position 2 of "&lt;b&gt;ab&lt;/b&gt;cd" falls inside the tag.
        /// </summary>
        private static bool UsesRawIndices(GUIStyle style)
        {
            if (indexMode >= 0)
                return indexMode == 1;

            var probe = new GUIContent("<b>ab</b>cd");
            var probeRect = new Rect(0f, 0f, 1000f, 100f);
            float start = style.GetCursorPixelPosition(probeRect, probe, 0).x;
            float atTwo = style.GetCursorPixelPosition(probeRect, probe, 2).x;
            indexMode = Mathf.Abs(atTwo - start) < 0.5f ? 1 : 0;
            return indexMode == 1;
        }

        private void DrawHeading(MdBlock block, float width)
        {
            GUIStyle style = block.level == 1 ? h1 : block.level == 2 ? h2 : block.level == 3 ? h3 : h4;
            Rect rect = WrappedLabel(block.text, style, width);

            if (block.level > 2)
                return;

            GUILayout.Space(block.level == 1 ? 6f : 4f);
            Rect line = GUILayoutUtility.GetRect(width, block.level == 1 ? 2f : 1f, GUILayout.Width(width));
            if (Event.current.type != EventType.Repaint)
                return;

            if (block.level == 1)
            {
                EditorGUI.DrawRect(line, theme.divider);
                EditorGUI.DrawRect(new Rect(line.x, line.y, Mathf.Min(64f, line.width), line.height), theme.accent);
            }
            else
            {
                EditorGUI.DrawRect(line, theme.divider);
            }
        }

        private void DrawListItem(MdBlock block, float width)
        {
            float indent = block.level * LIST_INDENT;
            float textX = indent + LIST_INDENT + 4f;
            float textWidth = Mathf.Max(40f, width - textX);

            GUIContent content = Temp(block.text);
            float height = Mathf.Max(body.CalcHeight(content, textWidth), 16f);
            Rect rect = GUILayoutUtility.GetRect(width, height, GUILayout.Width(width));

            Rect markerRect = new Rect(rect.x + indent, rect.y, LIST_INDENT, 16f);
            Rect textRect = new Rect(rect.x + textX, rect.y, textWidth, height);

            if (block.checkState >= 0)
            {
                GUI.Toggle(new Rect(markerRect.x + 2f, markerRect.y + 1f, 14f, 14f), block.checkState == 1, GUIContent.none);
            }
            else if (block.ordered)
            {
                GUI.Label(markerRect, block.marker, marker);
            }
            else if (Event.current.type == EventType.Repaint)
            {
                float size = block.level == 0 ? 5f : 4f;
                Rect dot = new Rect(markerRect.xMax - size - 2f, markerRect.y + 7f, size, size);
                EditorGUI.DrawRect(dot, block.level == 0 ? theme.accent : theme.muted);
            }

            GUI.Label(textRect, content, body);
            HandleLinks(textRect, content, body, block.links);
        }

        private void DrawCode(MdBlock block, float width)
        {
            GUIContent content = Temp(block.text);
            float bodyHeight = code.CalcHeight(content, width);
            Rect rect = GUILayoutUtility.GetRect(width, CODE_HEADER_HEIGHT + bodyHeight, GUILayout.Width(width));
            Rect header = new Rect(rect.x, rect.y, rect.width, CODE_HEADER_HEIGHT);
            Rect bodyRect = new Rect(rect.x, header.yMax, rect.width, bodyHeight);

            if (Event.current.type == EventType.Repaint)
            {
                DrawBorder(rect, theme.codeBorder);
                EditorGUI.DrawRect(Inset(header), theme.codeHeader);
                EditorGUI.DrawRect(Inset(bodyRect), theme.codeBackground);
            }

            string language = string.IsNullOrEmpty(block.language) ? "text" : block.language;
            GUI.Label(header, language.ToUpperInvariant(), codeLang);

            string copyLabel = lastCopied == block ? "Copied" : "Copy";
            Rect copyRect = new Rect(header.xMax - 64f, header.y + 2f, 60f, header.height - 4f);
            if (GUI.Button(copyRect, copyLabel, EditorStyles.miniButton))
            {
                GUIUtility.systemCopyBuffer = block.raw;
                lastCopied = block;
            }

            GUI.Label(bodyRect, content, code);
        }

        private void DrawCallout(MdBlock block, string docDir, float width)
        {
            Color color = theme.CalloutColor(block.callout);
            float innerWidth = width - calloutBox.padding.horizontal;

            Rect box = EditorGUILayout.BeginVertical(calloutBox, GUILayout.Width(width));
            if (Event.current.type == EventType.Repaint)
            {
                Color tint = color;
                tint.a = theme.dark ? 0.10f : 0.08f;
                EditorGUI.DrawRect(box, tint);
                EditorGUI.DrawRect(new Rect(box.x, box.y, 3f, box.height), color);
            }

            if (!string.IsNullOrEmpty(block.title))
            {
                Rect titleRect = GUILayoutUtility.GetRect(innerWidth, 20f, GUILayout.Width(innerWidth));
                Texture icon = CalloutIcon(block.callout);
                float x = titleRect.x;
                if (icon != null)
                {
                    GUI.DrawTexture(new Rect(x, titleRect.y + 2f, 16f, 16f), icon, ScaleMode.ScaleToFit);
                    x += 20f;
                }

                Color previous = calloutTitle.normal.textColor;
                calloutTitle.normal.textColor = color;
                GUI.Label(new Rect(x, titleRect.y, titleRect.xMax - x, titleRect.height), block.title, calloutTitle);
                calloutTitle.normal.textColor = previous;

                if (block.children.Count > 0)
                    GUILayout.Space(4f);
            }

            Draw(block.children, docDir, innerWidth);
            EditorGUILayout.EndVertical();
        }

        private static Texture CalloutIcon(CalloutKind kind)
        {
            string name;
            switch (kind)
            {
                case CalloutKind.Note:
                case CalloutKind.Important:
                case CalloutKind.Rule:
                    name = "console.infoicon.sml";
                    break;
                case CalloutKind.Warning:
                    name = "console.warnicon.sml";
                    break;
                case CalloutKind.Caution:
                    name = "console.erroricon.sml";
                    break;
                case CalloutKind.Do:
                case CalloutKind.Tip:
                    name = "TestPassed";
                    break;
                case CalloutKind.Dont:
                    name = "TestFailed";
                    break;
                default:
                    return null;
            }

            GUIContent content = EditorGUIUtility.IconContent(name);
            return content != null ? content.image : null;
        }

        private void DrawTable(MdBlock block, float width)
        {
            LayoutTable(block, width);
            Rect rect = GUILayoutUtility.GetRect(width, block.cachedHeight, GUILayout.Width(width));
            bool repaint = Event.current.type == EventType.Repaint;

            if (repaint)
                DrawBorder(rect, theme.tableBorder);

            float y = rect.y;
            for (int r = -1; r < block.rows.Count; r++)
            {
                string[] cells = r < 0 ? block.header : block.rows[r];
                float rowHeight = block.cachedRowHeights[r + 1];
                Rect rowRect = new Rect(rect.x, y, rect.width, rowHeight);

                if (repaint)
                {
                    if (r < 0)
                        EditorGUI.DrawRect(Inset(rowRect), theme.tableHeader);
                    else if (r % 2 == 1)
                        EditorGUI.DrawRect(Inset(rowRect), theme.tableRowAlt);

                    if (r >= 0)
                        EditorGUI.DrawRect(new Rect(rect.x, y, rect.width, 1f), theme.tableBorder);
                }

                List<MdLink>[] links = r < 0 ? block.headerLinks : block.rowLinks[r];
                DrawTableRow(block, cells, links, r < 0 ? tableHeader : tableCell, new Rect(rect.x, y, 0f, rowHeight));
                y += rowHeight;
            }
        }

        private void DrawTableRow(MdBlock block, string[] cells, List<MdLink>[] links, GUIStyle style, Rect row)
        {
            bool repaint = Event.current.type == EventType.Repaint;
            float x = row.x;
            float y = row.y;
            float height = row.height;
            for (int c = 0; c < cells.Length; c++)
            {
                float colWidth = block.cachedColumnWidths[c];
                Rect cell = new Rect(x, y, colWidth, height);
                TextAnchor previous = style.alignment;
                style.alignment = block.aligns[c];
                GUIContent content = Temp(cells[c]);
                GUI.Label(cell, content, style);
                HandleLinks(cell, content, style, links == null ? null : links[c]);
                style.alignment = previous;

                if (repaint && c > 0)
                    EditorGUI.DrawRect(new Rect(x, y, 1f, height), theme.tableBorder);

                x += colWidth;
            }
        }

        private void LayoutTable(MdBlock block, float width)
        {
            if (Mathf.Approximately(block.cachedWidth, width) && block.cachedColumnWidths != null)
                return;

            int columns = block.header.Length;
            var preferred = new float[columns];
            float total = 0f;

            for (int c = 0; c < columns; c++)
            {
                float max = tableHeader.CalcSize(Temp(block.header[c])).x;
                for (int r = 0; r < block.rows.Count; r++)
                    max = Mathf.Max(max, tableCell.CalcSize(Temp(block.rows[r][c])).x);
                preferred[c] = Mathf.Clamp(max, 48f, width * 0.65f);
                total += preferred[c];
            }

            float scale = width / Mathf.Max(1f, total);
            float assigned = 0f;
            for (int c = 0; c < columns; c++)
            {
                preferred[c] = c == columns - 1 ? width - assigned : Mathf.Floor(preferred[c] * scale);
                assigned += preferred[c];
            }

            var heights = new float[block.rows.Count + 1];
            float height = 0f;
            for (int r = -1; r < block.rows.Count; r++)
            {
                string[] cells = r < 0 ? block.header : block.rows[r];
                GUIStyle style = r < 0 ? tableHeader : tableCell;
                float rowHeight = 18f;
                for (int c = 0; c < columns; c++)
                    rowHeight = Mathf.Max(rowHeight, style.CalcHeight(Temp(cells[c]), preferred[c]));
                heights[r + 1] = rowHeight;
                height += rowHeight;
            }

            block.cachedWidth = width;
            block.cachedColumnWidths = preferred;
            block.cachedRowHeights = heights;
            block.cachedHeight = height;
        }

        private void DrawRule(float width)
        {
            Rect rect = GUILayoutUtility.GetRect(width, 9f, GUILayout.Width(width));
            if (Event.current.type == EventType.Repaint)
                EditorGUI.DrawRect(new Rect(rect.x, rect.y + 4f, rect.width, 1f), theme.divider);
        }

        private void DrawImage(MdBlock block, string docDir, float width)
        {
            Texture2D texture = LoadTexture(docDir, block.path);

            if (texture == null)
            {
                Rect missing = GUILayoutUtility.GetRect(width, 56f, GUILayout.Width(width));
                if (Event.current.type == EventType.Repaint)
                {
                    EditorGUI.DrawRect(missing, theme.tableRowAlt);
                    DrawBorder(missing, theme.tableBorder);
                }
                GUI.Label(missing, $"Image not found\n<color=#{theme.InlineCodeHex}>{block.path}</color>", placeholder);
                return;
            }

            bool retina = Path.GetFileNameWithoutExtension(block.path).EndsWith("@2x");
            float naturalWidth = retina ? texture.width * 0.5f : texture.width;
            float drawWidth = Mathf.Min(naturalWidth, width);
            float drawHeight = drawWidth * texture.height / Mathf.Max(1f, texture.width);

            Rect row = GUILayoutUtility.GetRect(width, drawHeight, GUILayout.Width(width));
            Rect imageRect = new Rect(row.x + (width - drawWidth) * 0.5f, row.y, drawWidth, drawHeight);
            GUI.DrawTexture(imageRect, texture, ScaleMode.ScaleToFit, true);
            if (Event.current.type == EventType.Repaint)
                DrawBorder(imageRect, theme.tableBorder);

            if (!string.IsNullOrEmpty(block.text))
            {
                GUILayout.Space(4f);
                WrappedLabel(block.text, caption, width);
            }
        }

        private Texture2D LoadTexture(string docDir, string relativePath)
        {
            string fullPath;
            try
            {
                fullPath = Path.GetFullPath(Path.Combine(docDir ?? string.Empty, relativePath));
            }
            catch (ArgumentException)
            {
                return null;
            }

            if (textures.TryGetValue(fullPath, out Texture2D cached))
                return cached;

            Texture2D texture = null;
            if (File.Exists(fullPath))
            {
                texture = new Texture2D(2, 2, TextureFormat.RGBA32, false) { hideFlags = HideFlags.HideAndDontSave };
                if (!texture.LoadImage(File.ReadAllBytes(fullPath)))
                {
                    UnityEngine.Object.DestroyImmediate(texture);
                    texture = null;
                }
            }

            textures[fullPath] = texture;
            return texture;
        }

        private void DrawFlow(MdBlock block, float width)
        {
            for (int r = 0; r < block.flowRows.Count; r++)
            {
                if (r > 0)
                    GUILayout.Space(FLOW_GAP);
                DrawFlowRow(block.flowRows[r], width);
            }
        }

        private void DrawFlowRow(List<FlowStep> steps, float width)
        {
            // First count how many lines the boxes take, to reserve the exact height.
            float boxHeight = flowStep.CalcHeight(Temp("Ag"), 200f);
            int lines = 1;
            float x = 0f;
            for (int i = 0; i < steps.Count; i++)
            {
                float needed = StepWidth(steps[i], width) + (i > 0 ? FLOW_ARROW_WIDTH : 0f);
                if (x > 0f && x + needed > width)
                {
                    lines++;
                    x = 0f;
                }
                x += needed;
            }

            float totalHeight = lines * boxHeight + (lines - 1) * FLOW_GAP;
            Rect area = GUILayoutUtility.GetRect(width, totalHeight, GUILayout.Width(width));

            x = 0f;
            float y = 0f;
            for (int i = 0; i < steps.Count; i++)
            {
                float stepWidth = StepWidth(steps[i], width);
                float needed = stepWidth + (i > 0 ? FLOW_ARROW_WIDTH : 0f);
                if (x > 0f && x + needed > width)
                {
                    x = 0f;
                    y += boxHeight + FLOW_GAP;
                }

                if (i > 0)
                {
                    GUI.Label(new Rect(area.x + x, area.y + y, FLOW_ARROW_WIDTH, boxHeight), "→", flowArrow);
                    x += FLOW_ARROW_WIDTH;
                }

                Rect box = new Rect(area.x + x, area.y + y, stepWidth, boxHeight);
                DrawFlowBox(steps[i], box);
                x += stepWidth;
            }
        }

        private float StepWidth(FlowStep step, float maxWidth)
        {
            return Mathf.Min(flowStep.CalcSize(Temp(step.label)).x, maxWidth);
        }

        private void DrawFlowBox(FlowStep step, Rect box)
        {
            if (Event.current.type == EventType.Repaint)
            {
                Color fill = step.color;
                fill.a = theme.dark ? 0.22f : 0.14f;
                EditorGUI.DrawRect(box, fill);
                DrawBorder(box, step.color);
                EditorGUI.DrawRect(new Rect(box.x, box.y, box.width, 2f), step.color);
            }
            GUI.Label(box, Temp(step.label), flowStep);
        }

        // ------------------------------------------------------------------ Utilities

        private GUIContent Temp(string text)
        {
            tempContent.text = text;
            tempContent.image = null;
            tempContent.tooltip = null;
            return tempContent;
        }

        private static Rect Inset(Rect rect)
        {
            return new Rect(rect.x + 1f, rect.y + 1f, rect.width - 2f, rect.height - 2f);
        }

        private static void DrawBorder(Rect rect, Color color)
        {
            EditorGUI.DrawRect(new Rect(rect.x, rect.y, rect.width, 1f), color);
            EditorGUI.DrawRect(new Rect(rect.x, rect.yMax - 1f, rect.width, 1f), color);
            EditorGUI.DrawRect(new Rect(rect.x, rect.y, 1f, rect.height), color);
            EditorGUI.DrawRect(new Rect(rect.xMax - 1f, rect.y, 1f, rect.height), color);
        }
    }
}
