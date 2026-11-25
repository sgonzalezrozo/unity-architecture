using System;
using System.Collections.Generic;
using UnityEngine;

namespace UnityArchitecture.Prefabs.Fixtures
{
    public enum AssetSpecFixtureKind
    {
        Weapon,
        Shield,
        Potion
    }

    [Serializable]
    public class AssetSpecFixtureItem
    {
        public int id;
        public string displayName;
        public AssetSpecFixtureKind kind;
    }

    /// <summary>A configuration asset for the AssetSpecs tests: a number, a text and a list of items.</summary>
    public class AssetSpecFixtureConfig : ScriptableObject
    {
        [SerializeField] private int version;
        [SerializeField] private string title;
        [SerializeField] private List<AssetSpecFixtureItem> items = new();

        public int Version => version;
        public string Title => title;
        public IReadOnlyList<AssetSpecFixtureItem> Items => items;
    }
}
