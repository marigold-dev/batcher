import React from 'react';
import Image from 'next/image';
import MarigoldLogo from '../img/marigold-logo.png';

const Footer = () => (
  <footer
    className={`bottom-0 left-0 right-0 border-t-4 border-lightgray bg-dark text-center`}>
    <div className="flex items-center p-4 text-center text-white">
      <div className="flex md:flex-row flex-col items-center justify-evenly grow">
        <div className="flex items-center">
          <a
            href="https://www.marigold.dev/"
            target="_blank"
            rel="noreferrer"
            className="text-zinc-400">
            ©{new Date().getFullYear()} Copyright Marigold
          </a>
          <Image alt="Marigold Logo" src={MarigoldLogo} />
        </div>

        <div>
          <a
            href="https://www.marigold.dev/contact"
            target="_blank"
            rel="noreferrer">
            Contact
          </a>
        </div>
        <div>
          <a
            href={`https://${
              process.env.NEXT_PUBLIC_NETWORK_TARGET === 'ghostnet'
                ? 'ghostnet.'
                : ''
            }batcher.marigold.dev/`}
            target="_blank"
            rel="noreferrer">
            {process.env.NEXT_PUBLIC_NETWORK_TARGET === 'ghostnet'
              ? 'Batcher Ghostnet'
              : 'Batcher Mainnet'}
          </a>
        </div>
        <div>
          <a href="https://tzkt.io/" target="_blank" rel="noreferrer">
            Powered by TzKT API
          </a>
        </div>
      </div>
    </div>
  </footer>
);

export default Footer;
