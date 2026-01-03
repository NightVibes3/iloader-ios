import "./Modal.css";

export const Modal = ({
  isOpen,
  close,
  sizeFit,
  children,
  hideClose,
}: {
  children: React.ReactNode;
  isOpen: boolean;
  close?: () => void;
  sizeFit?: boolean;
  hideClose?: boolean;
}) => {
  return (
    <>
      {isOpen && (
        <div className={`modal-container`}>
          <div className={`modal${sizeFit ? " size-fit" : ""}`}>
            {!hideClose && close && (
              <button
                className="modal-close"
                onClick={() => {
                  close();
                }}
              >
                &#x2715;
              </button>
            )}
            <div className="modal-content">{children}</div>
          </div>
        </div>
      )}
    </>
  );
};
