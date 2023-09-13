import Link from 'next/link';
import { usePathname } from 'next/navigation';
import React from 'react';

interface LinkProps {
  path: string;
  title: string;
  onClick?(): void;
}

const LinkComponent = ({ path, title, onClick }: LinkProps) => {
  const route = usePathname();

  return (
    <Link
      href={path}
      onClick={onClick}
      className={`${
        route === path
          ? 'bg-zinc-900'
          : 'text-zinc-300 hover:bg-zinc-700 hover:text-white'
      } block rounded-md px-3 py-2 text-base font-medium text-white md:text-sm`}
      aria-current="page">
      {title}
    </Link>
  );
};
export default LinkComponent;
