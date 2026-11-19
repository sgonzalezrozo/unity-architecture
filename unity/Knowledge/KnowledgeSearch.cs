using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace UnityArchitecture.Knowledge
{
    /// <summary>
    /// Búsqueda por relevancia. Todas las palabras deben aparecer. Ignora mayúsculas y tildes, y tolera
    /// errores de escritura ("recycable" encuentra "recyclable") en títulos, resúmenes y keywords.
    /// </summary>
    internal static class KnowledgeSearch
    {
        private const float TITLE_WEIGHT = 10f;
        private const float KEYWORD_EXACT_WEIGHT = 8f;
        private const float KEYWORD_PARTIAL_WEIGHT = 4f;
        private const float SUMMARY_WEIGHT = 4f;
        private const float CATEGORY_WEIGHT = 3f;
        private const float BODY_WEIGHT = 1f;
        private const float FUZZY_WEIGHT = 3f;
        private const int FUZZY_MIN_LENGTH = 4;
        private const int FUZZY_LONG_LENGTH = 7;

        private static readonly char[] WordSeparators =
            " \t\n\r.,;:!?()[]{}<>\"'`/\\|*_=+-#@&%$~^".ToCharArray();

        public static SearchIndex BuildIndex(KnowledgeEntry entry)
        {
            var index = new SearchIndex
            {
                title = Normalize(entry.title),
                summary = Normalize(entry.summary),
                category = Normalize(entry.category),
                body = Normalize(entry.markdownContent),
                keywords = new string[entry.keywords == null ? 0 : entry.keywords.Count]
            };

            for (int i = 0; i < index.keywords.Length; i++)
                index.keywords[i] = Normalize(entry.keywords[i]);

            index.words = CollectWords(index);
            return index;
        }

        public static string[] SplitQuery(string query)
        {
            return Normalize(query).Split(WordSeparators, StringSplitOptions.RemoveEmptyEntries);
        }

        public static float Score(KnowledgeEntry entry, string[] terms)
        {
            if (terms.Length == 0)
                return 1f;

            float total = 0f;
            for (int i = 0; i < terms.Length; i++)
            {
                float termScore = ScoreTerm(entry.search, terms[i]);
                if (termScore <= 0f)
                    return 0f;
                total += termScore;
            }
            return total;
        }

        public static int CompareByScore(KnowledgeEntry a, KnowledgeEntry b)
        {
            int byScore = b.score.CompareTo(a.score);
            return byScore != 0 ? byScore : a.index.CompareTo(b.index);
        }

        public static string Normalize(string text)
        {
            if (string.IsNullOrEmpty(text))
                return string.Empty;

            string decomposed = text.ToLowerInvariant().Normalize(NormalizationForm.FormD);
            var builder = new StringBuilder(decomposed.Length);
            for (int i = 0; i < decomposed.Length; i++)
            {
                if (CharUnicodeInfo.GetUnicodeCategory(decomposed[i]) != UnicodeCategory.NonSpacingMark)
                    builder.Append(decomposed[i]);
            }
            return builder.ToString();
        }

        private static float ScoreTerm(SearchIndex index, string term)
        {
            float score = 0f;
            if (index.title.Contains(term))
                score += TITLE_WEIGHT;
            score += ScoreKeywords(index, term);
            if (index.summary.Contains(term))
                score += SUMMARY_WEIGHT;
            if (index.category.Contains(term))
                score += CATEGORY_WEIGHT;
            if (index.body.Contains(term))
                score += BODY_WEIGHT;

            if (score <= 0f && MatchesAnyWordFuzzy(index.words, term))
                score = FUZZY_WEIGHT;
            return score;
        }

        private static float ScoreKeywords(SearchIndex index, string term)
        {
            float best = 0f;
            for (int i = 0; i < index.keywords.Length; i++)
            {
                if (index.keywords[i] == term)
                    return KEYWORD_EXACT_WEIGHT;
                if (index.keywords[i].Contains(term))
                    best = KEYWORD_PARTIAL_WEIGHT;
            }
            return best;
        }

        private static string[] CollectWords(SearchIndex index)
        {
            var words = new HashSet<string>();
            AddWords(words, index.title);
            AddWords(words, index.summary);
            for (int i = 0; i < index.keywords.Length; i++)
                AddWords(words, index.keywords[i]);

            var result = new string[words.Count];
            words.CopyTo(result);
            return result;
        }

        private static void AddWords(HashSet<string> words, string text)
        {
            string[] parts = text.Split(WordSeparators, StringSplitOptions.RemoveEmptyEntries);
            for (int i = 0; i < parts.Length; i++)
            {
                if (parts[i].Length >= FUZZY_MIN_LENGTH)
                    words.Add(parts[i]);
            }
        }

        private static bool MatchesAnyWordFuzzy(string[] words, string term)
        {
            if (term.Length < FUZZY_MIN_LENGTH)
                return false;

            int maxDistance = term.Length >= FUZZY_LONG_LENGTH ? 2 : 1;
            for (int i = 0; i < words.Length; i++)
            {
                if (IsClose(term, words[i], maxDistance))
                    return true;
            }
            return false;
        }

        /// <summary>Distancia de edición acotada, también contra el principio de la palabra (escritura a medias).</summary>
        private static bool IsClose(string term, string word, int maxDistance)
        {
            if (Math.Abs(word.Length - term.Length) <= maxDistance && Distance(term, word, maxDistance) <= maxDistance)
                return true;

            if (word.Length <= term.Length)
                return false;

            string prefix = word.Substring(0, term.Length);
            return Distance(term, prefix, maxDistance) <= maxDistance;
        }

        private static int Distance(string a, string b, int limit)
        {
            int[] previous = new int[b.Length + 1];
            int[] current = new int[b.Length + 1];
            for (int j = 0; j <= b.Length; j++)
                previous[j] = j;

            for (int i = 1; i <= a.Length; i++)
            {
                current[0] = i;
                int rowMin = current[0];
                for (int j = 1; j <= b.Length; j++)
                {
                    int cost = a[i - 1] == b[j - 1] ? 0 : 1;
                    current[j] = Math.Min(Math.Min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
                    rowMin = Math.Min(rowMin, current[j]);
                }

                if (rowMin > limit)
                    return rowMin;

                int[] swap = previous;
                previous = current;
                current = swap;
            }
            return previous[b.Length];
        }
    }
}
