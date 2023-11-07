import * as React from 'react';
import * as ToastBase from '@radix-ui/react-toast';
import { useSelector } from 'react-redux';
import { getToastInfosSelector } from '@/reducers';
import { useDispatch } from 'react-redux';
import { closeToast } from '@/actions';
import { createPortal } from 'react-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faCircleInfo, faCircleXmark } from '@fortawesome/free-solid-svg-icons';

const Toast = () => {
  const [PortalRoot, setPortalRoot] = React.useState<HTMLElement | null>(null);

  const { isToastOpen, toastDescription, type } = useSelector(
    getToastInfosSelector
  );
  const dispatch = useDispatch();

  React.useEffect(() => {
    // Avoid SSR with NextJS because document is not defined in server-side
    setPortalRoot(document.getElementById('portal'));
  }, []);

  if (!PortalRoot) return null;

  return createPortal(
    <ToastBase.Provider duration={5000}>
      <ToastBase.Root
        className="bg-white border border-solid border-black rounded p-[15px] grid [grid-template-areas:_'title_action'_'description_action'] grid-cols-[auto_max-content] gap-x-[15px] items-center data-[state=open]:animate-slideIn data-[state=closed]:animate-hide data-[swipe=move]:translate-x-[var(--radix-toast-swipe-move-x)] data-[swipe=cancel]:translate-x-0 data-[swipe=cancel]:transition-[transform_200ms_ease-out] data-[swipe=end]:animate-swipeOut"
        open={isToastOpen}
        onOpenChange={() => dispatch(closeToast())}>
        <div className="flex gap-6 items-center">
          <FontAwesomeIcon
            icon={type === 'error' ? faCircleXmark : faCircleInfo}
            size="2x"
            className={`${type === 'error' ? 'text-primary' : 'text-green'}`}
          />
          <div className="flex flex-col">
            <ToastBase.Title className="[grid-area:_title] mb-[5px] text-black">
              {type === 'error' ? 'Error' : 'Info'}
            </ToastBase.Title>
            <ToastBase.Description className="text-black text-sm" asChild>
              <p>{toastDescription}</p>
            </ToastBase.Description>
          </div>
        </div>
        <ToastBase.Action
          className="[grid-area:_action]"
          asChild
          altText="Undo">
          <button className="inline-flex items-center justify-center rounded text-xs text-white px-[10px] h-[25px] shadow-[inset_0_0_0_1px] bg-primary hover:bg-hovergray hover:text-black">
            Undo
          </button>
        </ToastBase.Action>
      </ToastBase.Root>
      <ToastBase.Viewport className="[--viewport-padding:_15px] fixed top-0 right-0 flex flex-col p-[var(--viewport-padding)] gap-[10px] w-[390px] max-w-[100vw] m-0 list-none z-[2147483647] outline-none" />
    </ToastBase.Provider>,
    PortalRoot
  );
};

export default Toast;
