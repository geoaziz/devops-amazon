import React from "react";
import ContentTile from "./ContentTile";
import ContentTileData from "./ContentTileData";

function renderContentTile(data) {
  return <ContentTile poster={data.poster} />;
}

function ContentCarousel() {
  return (
    <div style={{ marginBottom: 48 }}>
      <div style={{ marginLeft: 72, marginRight: 72, paddingBottom: 16 }}>
        Movies List
      </div>
      <div>
        <div style={{ display: "flex", overflow: "hidden" }}>
          <button
            onClick={() => {
              document.getElementById("container").scrollLeft -= 1400;
            }}
            style={{
              backgroundColor: "transparent",
              zIndex: 20,
            }}
          >
            left
          </button>

          <ul
            id="container"
            style={{
              alignItems: "flex-start",
              display: "flex",
              flexDirection: "row",
              listStyle: "none",
              margin: 0,
              overflowX: "scroll",
              padding: "72 72",
              scrollBehavior: "smooth",
              scrollSnapType: "x proximity",
              zIndex: 2,
            }}
          >
            {ContentTileData.map(renderContentTile)}
          </ul>

          <button
            onClick={() => {
              document.getElementById("container").scrollLeft += 1400;
            }}
            style={{
              appearance: "none",
              backgroundColor: "transparent",
              border: "none",
              zIndex: 20,
            }}
          >
            <img
              src="https://www.citypng.com/public/uploads/preview/right-arrowhead-black-11581593809dmlihnv7fa.png"
              alt="right"
              style={{ height: 20, width: 20 }}
            />
          </button>
        </div>
      </div>
    </div>
  );
}

export default ContentCarousel;
