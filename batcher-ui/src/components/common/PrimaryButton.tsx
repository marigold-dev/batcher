interface PrimaryButtonProps {
  title: string;
}

const PrimaryButton = ({ title }: PrimaryButtonProps) => (
  <button className="text-white h-10 disabled:cursor-not-allowed cursor-pointer disabled:bg-lightgray items-center justify-center rounded bg-primary px-4 mt-8 text-xl self-center">
    {title}
  </button>
);

export default PrimaryButton;
