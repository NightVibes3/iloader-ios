export type Operation = {
  id: string;
  title: string;
  successMessage?: string;
  successTitle?: string;
  steps: OperationStep[];
};

export type OperationStep = {
  id: string;
  title: string;
};

export type OperationState = {
  current: Operation;
  completed: string[];
  started: string[];
  failed: {
    stepId: string;
    extraDetails: string;
  }[];
};

type OperationInfoUpdate = {
  updateType: "started" | "finished";
  stepId: string;
};

type OperationFailedUpdate = {
  updateType: "failed";
  stepId: string;
  extraDetails: string;
};

export type OperationUpdate = OperationInfoUpdate | OperationFailedUpdate;

export const installSideStoreOperation: Operation = {
  id: "install_sidestore",
  title: "Installing SideStore",
  successTitle: "SideStore Installed!",
  successMessage: "Open SideStore and refresh it to complete the installation!",
  steps: [
    {
      id: "download",
      title: "Download SideStore",
    },
    {
      id: "install",
      title: "Sign & Install SideStore",
    },
    {
      id: "pairing",
      title: "Place Pairing File",
    },
  ],
};

export const installLiveContainerOperation: Operation = {
  id: "install_sidestore",
  title: "Installing LiveContainer+SideStore",
  successTitle: "LiveContainer+SideStore Installed!",
  successMessage:
    'To complete the installation, open LiveContainer, choose settings, and click "Import Certificate From SideStore." Then, choose apps, click the sidestore icon, and refresh LiveContainer.',
  steps: [
    {
      id: "download",
      title: "Download SideStore+LiveContainer",
    },
    {
      id: "install",
      title: "Sign & Install SideStore+LiveContainer",
    },
    {
      id: "pairing",
      title: "Place Pairing File",
    },
  ],
};

export const sideloadOperation = {
  id: "sideload",
  title: "Installing App",
  steps: [
    {
      id: "install",
      title: "Sign & Install App",
    },
  ],
};
