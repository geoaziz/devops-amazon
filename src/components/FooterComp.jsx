import React from "react";

function Footer() {
  const year = new Date().getFullYear();
  return (
    <footer className="footer-container">
      <div className="logo"></div>
      <ul className="footer-ul">
        <li className="footer-li">
          <a href="https://www.amazon.com/gp/help/customer/display.html?nodeId=508088" className="footer-anchor">
            Terms and Privacy Notice
          </a>
        </li>
        <li className="footer-li">
          <a href="https://www.amazon.com/hz/contact-us/foresight/hubgateway" className="footer-anchor">
            Send us feedback
          </a>
        </li>
        <li className="footer-li">
          <a href="https://www.amazon.com/gp/help/customer/display.html" className="footer-anchor">
            Help
          </a>
        </li>
        <li className="footer-li">
          © 1996-{year}, Amazon.com, Inc. or its affiliates
        </li>
      </ul>
    </footer>
  );
}

export default Footer;
