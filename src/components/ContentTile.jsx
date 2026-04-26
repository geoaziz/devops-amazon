import React from "react";

function ContentTile(props) {
  return (
    <li style={{ marginRight: 24 }}>
      <article>
        <section style={{ zIndex: 2 }}>
          <div>
            <img
              style={{
                height: 140,
                width: 248,
                borderRadius: 8,
              }}
              src={props.poster}
              alt="poster"
            ></img>
            {/* {isHovering && (
              <article>
                <div></div>
                <section></section>
                <h4>abc</h4>
                <section></section>
                <div></div>
              </article>
            )} */}
          </div>
        </section>
      </article>
    </li>
  );
}

export default ContentTile;
