import React from "react";
import HeaderComp from "./HeaderComp";
import BodyComp from "./BodyComp";
import FooterComp from "./FooterComp";

function App() {
  return (
    <body style={{ backgroundColor: "black" }}>
      <HeaderComp />
      <BodyComp />
      <FooterComp />
    </body>
  );
}

export default App;
