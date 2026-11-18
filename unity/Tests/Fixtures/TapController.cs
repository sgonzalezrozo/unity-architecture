using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace UnityArchitecture.Prefabs.Fixtures
{
    public class TapController : Graphic, IPointerClickHandler
    {
        public void OnPointerClick(PointerEventData eventData)
        {
        }

        protected override void OnPopulateMesh(VertexHelper vertexHelper)
        {
            vertexHelper.Clear();
        }
    }
}
