import { TwitterOutlined, GithubOutlined } from "@ant-design/icons";
import React from "react";
import Image from "next/image";
import MarigoldLogo from "../../img/marigold-logo.png";

const Footer = () => (
  <footer className="font-custom flex justify-between max-h-fit">
    <a href="https://www.marigold.dev/">
      <div className="flex items-end">
        <h1 style={{ marginBottom: '0', fontSize: '16px', color: '#FFFFFF' }}>
          MARIGOLD
        </h1>
        <Image alt="Marigold Logo" src={MarigoldLogo} />
      </div>
    </a>
    <div>
      <a href="https://twitter.com/Marigold_Dev">
        <TwitterOutlined style={{ color: '#FFFFFF', fontSize: 24 }} />
      </a>
      <a href="https://github.com/marigold-dev/batcher">
        <GithubOutlined style={{ color: '#FFFFFF', fontSize: 24 }} />
      </a>
    </div>
  </footer>
);

export default Footer;
